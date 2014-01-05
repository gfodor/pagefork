express = require "express"
module.exports = app = express()
hat = require "hat"
AWS = require "aws-sdk"

app.get "/phorks/new", (req, res) ->
  phork_id = hat()
  s3 = new AWS.S3()
  mhtml_url = s3.getSignedUrl "putObject", Bucket: "phork-data", ContentType: "multipart/related", Key: "uploads/mhtml/#{phork_id}.mhtml"

  res.send { mhtml_url: mhtml_url }
