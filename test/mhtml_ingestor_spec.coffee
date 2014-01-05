should = require('should')
MHTMLIngestor = require('../lib/mhtml_ingestor.js')

describe "Ingestion", ->
  it "should do something", (done) ->
    ingestor = new MHTMLIngestor()
    ingestor.ingest "test/assets/etsy-search", "test/assets/etsy-search/http:/www.etsy.com/search?q=scarf&view_type=gallery&ship_to=US", ->
      done()
