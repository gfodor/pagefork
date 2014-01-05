express = require "express"
hat = require "hat"
AWS = require "aws-sdk"
mhtml = require "../lib-3rd/mhtml"
temp = require "temp"
fs = require "fs"

module.exports = app = express()

temp.track()

app.use express.urlencoded()
app.use express.json()

app.get "/phorks/new", (req, res) ->
  phork_id = hat()
  s3 = new AWS.S3()

  s3.getSignedUrl "putObject",
    Bucket: "phork-data",
    ContentType: "multipart/related",
    Key: "uploads/mhtml/#{phork_id}.mhtml", (err, mHtmlUrl) ->
      res.send { mhtml_url: mHtmlUrl, phork_id: phork_id }

app.post "/phorks", (req, res) ->
  s3 = new AWS.S3()
  phork_id = req.body.phork_id
  return res.send(400, "Required argment phork_id missing.") unless phork_id

  s3.getObject
    Bucket: "phork-data",
    Key: "uploads/mhtml/#{phork_id}.mhtml", (err, mhtmlData) ->
      temp.open "#{phork_id}.temp.mhtml", (err, mhtmlTempInfo) ->
        fs.write mhtmlTempInfo.fd, mhtmlData.Body, 0, mhtmlData.ContentLength, null, (err, mhtmlWritten, mhtmlBuffer) ->
          fs.close(mhtmlTempInfo.fd)

          mhtml.extract mhtmlTempInfo.path, "foomhtml", ((err, primaryContentPath) ->
            console.log(primaryContentPath)), false, true

  res.send({})

