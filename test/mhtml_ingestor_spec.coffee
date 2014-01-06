should = require('should')
assert = require('assert')
_ = require "lodash"

MHTMLIngestor = require('../lib/mhtml_ingestor.js')

describe "Ingestion", ->
  it "should do something", (done) ->
    ingestor = new MHTMLIngestor()
    path = "test/assets/etsy-search"
    primary_path = "#{path}/http:/www.etsy.com/search?q=scarf&view_type=gallery&ship_to=US"

    ingestor.ingest path, primary_path, (err, docs) ->
      assert.equal _.keys(docs).length, 3
      done()
