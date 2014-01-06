should = require('should')
assert = require('assert')
_ = require "lodash"

MHTMLIngestor = require('../lib/mhtml_ingestor.js')

describe "Ingestion", ->
  it "should do something", (done) ->
    ingestor = new MHTMLIngestor()
    path = "test/assets/etsy-search"
    primaryContentPath = "#{path}/http:/www.etsy.com/search?q=scarf&view_type=gallery&ship_to=US"

    ingestor.ingest path, primaryContentPath, (err, docs) ->
      assert.equal docs.length, 3
      done()
