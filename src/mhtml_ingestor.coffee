fs = require "fs"
async = require "async"
cheerio = require "cheerio"
htmltidy = require "htmltidy"
cssbeautify = require "cssbeautify"
_ = require "lodash"

module.exports = class MHTMLIngestor
  ingest: (sourceDir, primaryContentPath, cb) ->
    self = this
    self.callback = cb

    this.getFiles sourceDir, (err, files) ->
      return self.callback(err) if err

      processors = {}

      for path in files
        isPrimary = primaryContentPath == path

        processors[path] = ((path, isPrimary) ->
          (cb) -> self.documentForPath(path, isPrimary, cb)
        )(path, isPrimary)

      async.parallel processors, (err, results) ->
        self.callback(err, _.compact(_.values(results)))

  documentForPath: (path, isPrimary, callback) ->
    fs.readFile "#{path}.meta.json", (err, data) =>
      return callback(null) if err

      meta = JSON.parse(data)
      isCss = /\.css$/i.test(path)
      isNotHtml = false

      if meta? && meta["content-type"]
        isCss = meta["content-type"].toLowerCase() == "text/css"
        isNotHtml = meta["content-type"].toLowerCase() != "text/html"

      if isCss
        this.cssDocumentForPath(path, callback)
      else if !isNotHtml && isPrimary
        this.htmlDocumentForPath(path, isPrimary, callback)
      else
        callback(null)

  cssDocumentForPath: (path, callback) ->
    documentName = _.last(path.split("/"))

    fs.readFile path, 'utf8', (err, data) ->
      css = cssbeautify data, { indent: '  ' }
      callback(null, { name: documentName, content: css })
    
  htmlDocumentForPath: (path, isPrimary, callback) ->
    documentName = _.last(path.split("/"))

    fs.readFile path, 'utf8', (err, data) ->
      $ = cheerio.load(data)

      # Remove CSS
      $("link[rel='stylesheet']").remove()
      $("link[rel='Stylesheet']").remove()
      $("link[rel='StyleSheet']").remove()
      $("link[rel='STYLESHEET']").remove()

      title = $("title").text()
      htmltidy.tidy $("body").html() || "", { hideComments: true, indent: true }, (err, html) ->
        callback(null, { name: documentName, primary: isPrimary, content: html  })

  getFiles: (dir, cb) ->
    pending = [dir]
    allFiles = []

    async.whilst (-> pending.length > 0), ((callback) ->
      next = pending.pop()

      fs.readdir next, (err, files) ->
        return cb(err) if err

        files ?= []

        for file in files
          path = "#{next}/#{file}"
          stat = fs.statSync(path)

          if stat.isFile()
            allFiles.push(path)
          else if stat.isDirectory()
            pending.push(path)

        callback()
    ), ((err) -> cb(err, allFiles))

