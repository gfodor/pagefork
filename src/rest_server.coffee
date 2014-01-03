express = require "express"
module.exports = app = express()
AWS = require "aws-sdk"

app.get "/", (req, res) ->
  s3 = new AWS.S3()
  url = s3.getSignedUrl "putObject", Bucket: "phork-data", Key: "foo5"

  res.send url
