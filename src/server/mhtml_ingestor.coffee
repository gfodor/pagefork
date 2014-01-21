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

    this.withCssMetadata primaryContentPath, (err, cssMetadata) =>
      this.getFiles sourceDir, (err, files) ->
        return self.callback(err) if err

        processors = {}

        for path in files
          isPrimary = primaryContentPath == path

          processors[path] = ((path, isPrimary) ->
            (cb) -> self.documentsForPath(path, isPrimary, cssMetadata, cb)
          )(path, isPrimary)

        async.parallel processors, (err, results) ->
          self.callback(err, _.compact(_.flatten(_.values(results))))

  withCssMetadata: (primaryContentPath, callback) ->
    fs.readFile primaryContentPath, 'utf8', (err, data) =>
      $ = cheerio.load(data)

      cssMeta = {}

      # Remove CSS
      for link in $("link")
        if ($(link).attr("rel") || "").toLowerCase() == "stylesheet"
          href = $(link).attr("href")
          media = $(link).attr("media")

          if href
            cssMeta[href] = { }
            cssMeta[href].media = media if media

      callback(null, cssMeta)

  documentsForPath: (path, isPrimary, cssMetadata, callback) ->
    fs.readFile "#{path}.meta.json", (err, data) =>
      return callback(null) if err

      meta = JSON.parse(data)
      isCss = /\.css$/i.test(path)
      isNotHtml = false

      if meta?
        if meta["content-type"]
          isCss = meta["content-type"].toLowerCase() == "text/css"
          isNotHtml = meta["content-type"].toLowerCase() != "text/html"

        if meta["mhtml-file-offset"]?
          fileIndex = meta["mhtml-file-offset"]

      if isCss
        this.documentsForCssPath(path, fileIndex, cssMetadata, callback)
      else if !isNotHtml && isPrimary
        this.documentsForHtmlPath(path, isPrimary, fileIndex, callback)
      else
        callback(null)

  documentsForCssPath: (path, fileIndex, cssMetadata, callback) ->
    fs.readFile "#{path}.meta.json", (err, data) =>
      return callback(null) if err

      docMeta = JSON.parse(data)
      documentName = _.last(path.split("/"))

      fs.readFile path, 'utf8', (err, data) =>
        css = this.cssContentFromRawCss(data)
        docLocation = docMeta["content-location"].toLowerCase()

        docs = []

        for path, cssMetaCandidate of cssMetadata
          if docLocation.indexOf(path.toLowerCase()) == 0
            cssMeta = cssMetaCandidate

        if cssMeta
          doc =
            type: "css"
            index: fileIndex
            name: documentName
            content: css

          doc.media = cssMeta.media if cssMeta && cssMeta.media
          docs.push(doc)

        callback(null, [docs])
    
  cssContentFromRawCss: (css) ->
    css = _.map(css.split("\n"), (l) ->
      # MHTML export expands "background:0" into this:
      l.replace("background-position: 0px 50%; background-repeat: initial initial", "background:0")
    ).join("\n")

    css = cssbeautify css, { indent: '  ' }
    lines = css.split("\n")
    lines = _.reject(lines, (l) -> l.match(/@import/i))

    lines = _.map lines, (l) ->
      l = l.replace(/(local|url)\(([^'"][^)]+)\)/ig, "$1('$2')")

    css = lines.join("\n")

  documentsForHtmlPath: (path, isPrimary, fileIndex, callback) ->
    documentName = _.last(path.split("/"))

    fs.readFile path, 'utf8', (err, data) =>
      $ = cheerio.load(data)

      doctype = null

      for line in data.split(/\n/)[0..10]
        matches = /(<\!doctype[^>]*>)/i.exec(line)

        if matches && matches.length > 0
          doctype = matches[0]

      # Remove CSS
      $("link[rel='stylesheet']").remove()
      $("link[rel='Stylesheet']").remove()
      $("link[rel='StyleSheet']").remove()
      $("link[rel='STYLESHEET']").remove()

      documents = []
      inlineIndex = 0

      # Generate documents for inline styles
      _.each $("style"), (style) =>
        inlineIndex += 1
        documents.push
          type: "css"
          name: "#{hat(100, 36)}.css"
          content: this.cssContentFromRawCss($(style).html())
          index: (100000 + inlineIndex) # Put the inline styles last

        $(style).remove()
      
      title = $("title").text()

      bodyHtml = $("body").html() || ""
      $("body").empty()

      bodyTag = $("body").toString().replace("</body>", "")
      htmlTag = "<html>"

      if ($("html").length > 0)
        $("html").empty()
        htmlTag = $("html").toString().replace("</html>", "")

      tidyOps =
        hideComments: true
        indent: true
        wrap: 160
        
      tidyOps["logical-emphasis"] = true
      tidyOps["output-html"] = true
      tidyOps["show-body-only"] = true

      blockTags = ["ul", "li", "ol", "dl", "dd", "dt"]

      tidyOps["new-blocklevel-tags"] = _.map(blockTags, (t) -> "#{t}-ignore").join(" ")

      finalize = (err, html) ->
        for tag in blockTags
          pattern = new RegExp("<(/?)#{tag}-ignore", "gi")
          html = html.replace(pattern, "<$1#{tag}")

        html = html.replace(/__NBSP/g, "&nbsp;")

        indentedHtml = _.map(html.match(/[^\r\n]+/g), (s) -> "    #{s}").join("\n")
        finalHtml = "#{htmlTag}\n  #{bodyTag}\n#{indentedHtml}\n  </body></html>"

        doc =
          type: "html"
          name: documentName
          index: fileIndex
          primary: isPrimary
          content: finalHtml

        doc.doctype = doctype if doctype
        documents.push doc

        callback(null, documents)

      # Add in inferred nbsps
      bodyHtml = bodyHtml.replace(/\/(b|big|i|small|tt|abbr|acronym|cite|code|dfn|em|kbd|strong|samp|var|a|bdo|br|img|map|object|q|script|span|sub|sup|button|input|label|select|textarea)>\s+<\s*(b|big|i|small|tt|abbr|acronym|cite|code|dfn|em|kbd|strong|samp|var|a|bdo|br|img|map|object|q|script|span|sub|sup|button|input|label|select|textarea)/gi, "/$1>__NBSP<$2")
      bodyHtml = bodyHtml.replace(/\/(b|big|i|small|tt|abbr|acronym|cite|code|dfn|em|kbd|strong|samp|var|a|bdo|br|img|map|object|q|script|span|sub|sup|button|input|label|select|textarea)>\s+([A-Z0-9,'"$()#@!])/gi, "/$1>__NBSP$2")
      bodyHtml = bodyHtml.replace(/([A-Z0-9,'"$#()@!])\s+<(b|big|i|small|tt|abbr|acronym|cite|code|dfn|em|kbd|strong|samp|var|a|bdo|br|img|map|object|q|script|span|sub|sup|button|input|label|select|textarea)/gi, "$1__NBSP<$2")

      # Tidy does some fuckery with ul, ol, dl, table
      for tag in blockTags
        pattern = new RegExp("<\\s*(/?)\\s*#{tag}([\\s>])", "gi")
        bodyHtml = bodyHtml.replace(pattern, "<$1#{tag}-ignore$2")

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

