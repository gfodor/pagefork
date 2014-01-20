async = require "async"
_ = require "lodash"
AWS = require "aws-sdk"
zlib = require "zlib"
hat = require "hat"

module.exports = class PhorkWriter
  writePhork: (phork_id, user_id, primaryContentDomain, docs, livedb, callback) ->
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
        async.eachLimit docs, 4,
          ((doc, callback) -> self.writePhorkDocument(dyndb, phork_id, doc, livedb, callback)),
          callback

  writePhorkDocument: (dyndb, phork_id, doc, livedb, callback) ->
    self = this
    doc_id = hat 100, 36

    item =
      phork_id: { S: phork_id },
      doc_id: { S: doc_id },
      name: { S: doc.name },
      type: { S: doc.type },
      created_at: { N: _.now().toString() },
      index: { N: doc.index.toString() }
      primary: { N: if doc.primary then "1" else "0" }

    item.media = { S: doc.media } if doc.media
    item.doctype = { S: doc.doctype } if doc.doctype

    dyndb.putItem
      TableName: 'phork_docs'
      Item: item, (err, data) ->
        return callback(err) if err

        collection = livedb.collection "docs"
        collection.submit doc_id, { v: 0, create: { type: 'text', data: doc.content } }, callback
