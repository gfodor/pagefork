async = require "async"
_ = require "lodash"
aws = require "aws-sdk"
zlib = require "zlib"
hat = require "hat"

aws.config.loadFromPath('config/aws.json')

module.exports = class PhorkWriter
  writePhork: (phork_id, user_id, primaryContentDomain, docs, callback) ->
    self = this

    dyndb = new aws.DynamoDB(region: "us-east-1")

    item =
      phork_id: { S: phork_id },
      user_id: { S: user_id },
      created_at: { N: _.now().toString() },
      primary_content_domain: { S: primaryContentDomain }

    dyndb.putItem
      TableName: "phork_roots#{self.tableSuffix()}",
      Item: item, (err) ->
        async.each docs,
          ((doc, callback) -> self.writePhorkDocument(dyndb, phork_id, doc, callback)),
          callback

  writePhorkDocument: (dyndb, phork_id, doc, callback) ->
    self = this

    zlib.gzip doc.content, (err, gzipContent) ->
      item =
        phork_content_id: { S: hat 100, 36 },
        phork_id: { S: phork_id },
        name: { S: doc.name },
        created_at: { N: _.now().toString() },
        content: { B: gzipContent.toString('base64') },
        primary: { N: if doc.primary? then "1" else "0" }

      dyndb.putItem
        TableName: "phork_content#{self.tableSuffix()}"
        Item: item, callback
 
  tableSuffix: ->
    if process.env.NODE_ENV == "production" then "" else "_development"
