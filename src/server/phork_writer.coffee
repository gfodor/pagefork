async = require "async"
_ = require "lodash"
AWS = require "aws-sdk"
zlib = require "zlib"
hat = require "hat"
livedbdynamodb = require "livedb-dynamodb"
AWS.config.loadFromPath('config/aws.json')
livedb = (require "livedb").client(livedbdynamodb(new AWS.DynamoDB()))

module.exports = class PhorkWriter
  writePhork: (phork_id, user_id, primaryContentDomain, docs, callback) ->
    self = this

    dyndb = new AWS.DynamoDB()

    item =
      phork_id: { S: phork_id },
      user_id: { S: user_id },
      created_at: { N: _.now().toString() },
      primary_content_domain: { S: primaryContentDomain }

    dyndb.putItem
      TableName: 'phork_roots',
      Item: item, (err) ->
        async.each docs,
          ((doc, callback) -> self.writePhorkDocument(dyndb, phork_id, doc, callback)),
          callback

  writePhorkDocument: (dyndb, phork_id, doc, callback) ->
    self = this
    doc_id = hat 100, 36

    item =
      phork_id: { S: phork_id },
      doc_id: { S: doc_id },
      name: { S: doc.name },
      created_at: { N: _.now().toString() },
      primary: { N: if doc.primary then "1" else "0" }

    dyndb.putItem
      TableName: 'phork_docs'
      Item: item, (err, data) ->
        return callback(err) if err

        # TODO redis
        collection = livedb.collection "docs"
        collection.submit doc_id, { v: 0, create: { type: 'text', data: doc.content } }, callback
 
  tableSuffix: ->
    if process.env.NODE_ENV == "production" then "" else "_development"
