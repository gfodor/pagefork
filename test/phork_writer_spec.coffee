should = require('should')
assert = require('assert')
hat = require('hat')

_ = require "lodash"

PhorkWriter = require '../lib/phork_writer.js'

describe "PhorkWrite", ->
  it "should write phork docs", (done) ->
    writer = new PhorkWriter()
    phork_id = hat 100, 36
    user_id = hat 100, 36

    docs = [{ name: "doc1", content: "content1", primary: true },
            { name: "doc2", content: "content2" }]

    writer.writePhork phork_id, user_id, docs, (err) ->
      assert.equal err, null
      done()
