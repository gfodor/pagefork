express = require "express"
hat = require "hat"
AWS = require "aws-sdk"
mhtml = require "mhtml"
temp = require "temp"
fs = require "fs"
cors = require "cors"
url = require "url"

MHTMLIngestor = require '../lib/mhtml_ingestor'
PhorkWriter = require '../lib/phork_writer'

module.exports = app = express()

temp.track()

app.use express.urlencoded()
app.use express.json()
app.use cors()

app.get "/phorks/new", (req, res) ->
  phork_id = hat 100, 36
  s3 = new AWS.S3()

  s3.getSignedUrl "putObject",
    Bucket: "phork-data",
    ContentType: "multipart/related",
    Key: "uploads/mhtml/#{phork_id}.mhtml", (err, mHtmlUrl) ->
      res.send { mhtml_url: mHtmlUrl, phork_id: phork_id }

app.post "/phorks", (req, res) ->
  s3 = new AWS.S3()
  phork_id = req.body.phork_id
  user_id = hat 100, 36

  return res.send(400, "Required argment phork_id missing.") unless phork_id
  ingestor = new MHTMLIngestor()
  writer = new PhorkWriter()

  temp.mkdir "phork", (err, tempPath) ->
    s3.getObject
      Bucket: "phork-data",
      Key: "uploads/mhtml/#{phork_id}.mhtml", (err, mhtmlData) ->
        return res.send(500, err) if err
        temp.open "#{phork_id}.temp.mhtml", (err, mhtmlTempInfo) ->
          return res.send(500, err) if err

          fs.write mhtmlTempInfo.fd, mhtmlData.Body, 0, mhtmlData.ContentLength, null, (err, mhtmlWritten, mhtmlBuffer) ->
            return res.send(500, err) if err
            fs.close(mhtmlTempInfo.fd)

            mhtml.extract mhtmlTempInfo.path, tempPath, false, true, true, (err, primaryContentPath, primaryContentUrl) ->
              return res.send(500, err) if err

              primaryContentDomain = ""

              if primaryContentUrl?
                primaryUrl = url.parse(primaryContentUrl)

                if primaryUrl.host?
                  primaryContentDomain = primaryUrl.host

              ingestor.ingest tempPath, primaryContentPath, (err, docs) ->
                return res.send(500, err) if err

                writer.writePhork phork_id, user_id, primaryContentDomain, docs, (err) ->
                  return res.send(500, err) if err
                  res.send({ docs: docs })

