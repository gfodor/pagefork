fs = require "fs"
async = require "async"
cheerio = require "cheerio"
htmltidy = require "htmltidy"
cssbeautify = require "cssbeautify"
hat = require "hat"
htmlpretty = require "html"
_ = require "lodash"
cssparse = require "css"
gonzales = require "gonzales"

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
          (cb) -> self.documentsForPath(path, isPrimary, cb)
        )(path, isPrimary)

      async.parallel processors, (err, results) ->
        self.callback(err, _.compact(_.flatten(_.values(results))))

  documentsForPath: (path, isPrimary, callback) ->
    fs.readFile "#{path}.meta.json", (err, data) =>
      return callback(null) if err

      meta = JSON.parse(data)
      isCss = /\.css$/i.test(path)
      isNotHtml = false

      if meta? && meta["content-type"]
        isCss = meta["content-type"].toLowerCase() == "text/css"
        isNotHtml = meta["content-type"].toLowerCase() != "text/html"

      if isCss
        this.documentsForCssPath(path, callback)
      else if !isNotHtml && isPrimary
        this.documentsForHtmlPath(path, isPrimary, callback)
      else
        callback(null)

  documentsForCssPath: (path, callback) ->
    documentName = _.last(path.split("/"))

    fs.readFile path, 'utf8', (err, data) =>
      css = this.cssContentFromRawCss(data)
      callback(null, [{ type: "css", name: documentName, content: css }])
    
  cssContentFromRawCss: (css) ->
    # Try parsing it to clean it first
    #try
    #  cssp = gonzales.srcToCSSP(css)
    #  css = gonzales.csspToSrc(cssp)
    #catch e
    #  try
    #    css = cssparser.stringify(cssparser.parse(css))
    #  catch f

    css = cssbeautify css, { indent: '  ' }
    css = css.replace(/!ie[0-9]?/gi, "")

    # Fix '@  page'
    css = css.replace(/@\s+/g, "@")

  documentsForHtmlPath: (path, isPrimary, callback) ->
    documentName = _.last(path.split("/"))

    fs.readFile path, 'utf8', (err, data) =>
      $ = cheerio.load(data)

      # Remove CSS
      $("link[rel='stylesheet']").remove()
      $("link[rel='Stylesheet']").remove()
      $("link[rel='StyleSheet']").remove()
      $("link[rel='STYLESHEET']").remove()

      documents = []

      # Generate documents for inline styles
      _.each $("style"), (style) =>
        documents.push
          type: "css"
          name: "#{hat(100, 36)}.css"
          content: this.cssContentFromRawCss($(style).html())

        $(style).remove()
      
      title = $("title").text()

      bodyHtml = $("body").html() || ""
      $("body").empty()
      $("body").addClass($("html").attr("class") || "")

      bodyTag = $("body").toString().replace("</body>", "")

      tidyOps =
        hideComments: true
        indent: true
        wrap: 160
        
      tidyOps["logical-emphasis"] = true
      tidyOps["output-html"] = true
      tidyOps["show-body-only"] = true

      prettyOps =
        indent_size: 2
        indent_char: " "
        max_char: 160

      finalize = (err, html) ->
        indentedHtml = _.map(html.match(/[^\r\n]+/g), (s) -> "  #{s}").join("\n")
        finalHtml = "#{bodyTag}\n#{indentedHtml}\n</body>"

        documents.push
          type: "html"
          name: documentName
          primary: isPrimary
          content: finalHtml

        callback(null, documents)

      # Try regular pretty print and then tidy, hacky
      # pretty fails on etsy.com
      # tidy screws up cnn.com
      try
        finalize(null, htmlpretty.prettyPrint(bodyHtml, prettyOps))
      catch e
        htmltidy.tidy(bodyHtml, tidyOps, finalize)


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

