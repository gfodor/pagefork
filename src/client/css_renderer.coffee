window.CssRenderer = class CssRenderer
  constructor: (@el) ->
    @domMap = {}

  stringHash: (st) ->
    hash = 0
    l = st.length

    return hash if l == 0

    for i in [0...l]
      char = st.charCodeAt(i)
      hash = ((hash << 5) - hash) + char
      hash |= 0

    hash

  update: (doc_id, styleSheet) ->
    window.s = styleSheet

    self = this

    seenCsses = {}
    currentMedia = null

    handleCssQuirks = (css) ->
      # Must enforce quotes around url/local references
      css = css.replace(/(local|url)\(([^'"][^)]+)\)/ig, "$1('$2')")
      # Chrome MHTML export translates background:0 to this
      css.replace("background-position: 0px 50%; background-repeat: initial initial", "background:0")

    styleRuleToString = (styleRule) ->
      selector = styleRule.selectorText
      selector = selector.replace(/(^|\s)body(\s|!|\.|#|$)/gi, "$1.phork-html-body$2")
      selector = selector.replace(/(^|\s)html(\s|!|\.|#|$)/gi, "$1$2")
      selector = _.map(selector.split(","), (s) -> ".phork-html #{s}").join(",")
      selector = selector.replace(/\s\s+/gi, " ")

      css = "#{selector} { #{styleRule.style.cssText} }"

      if styleRule.parentRule
        if styleRule.parentRule.type == 4
          css = "@media #{styleRule.parentRule.media.mediaText} { #{css} }"

      handleCssQuirks(css)

    processNode = (n) ->
      if n.type == 1
        css = styleRuleToString(n)
      else if n.type == 4
        # note must use loop here, it's a object not an array!
        for i in [0...(n.cssRules.length)]
          processNode(n.cssRules[i])

        return
      else
        css = handleCssQuirks(n.cssText)

      hash = self.stringHash(css)
      return if css == ""

      if seenCsses[hash]
        seenCsses[hash] = [seenCsses[hash]] unless _.isArray(seenCsses[hash])
        seenCsses[hash].push(css)
      else
        seenCsses[hash] = css

      currentEntry = null
      entries = self.domMap[hash]

      if entries
        if _.isArray(entries)
          for candidateCurrentEntry in entries
            currentEntry = candidateCurrentEntry if candidateCurrentEntry.css == css
        else
          currentEntry = entries if entries.css == css

      unless currentEntry
        node = $("<style>").text(css)
        $(self.el).append(node)

        if entries
          unless _.isArray(entries)
            entries = self.domMap[hash] = [entries]

          entries.push { hash: hash, css: css, node: node }
        else
          self.domMap[hash] = { hash: hash, css: css, node: node }

    # note must use loop here, it's a object not an array!
    for i in [0...styleSheet.rules.length]
      processNode(styleSheet.rules[i])

    for existingHash in _.keys(self.domMap)
      entries = self.domMap[existingHash]

      if _.isArray(entries)
        entriesToRemove = []

        for entry in entries
          if seenCsses[entry.hash]
            if (_.isArray(seenCsses[entry.hash]) && !_.include(seenCsses[entry.hash], entry.css)) ||
                (!_.isArray(seenCsses[entry.hash]) && seenCsses[entry.hash] != entry.css)
              entriesToRemove.push(entry)
          else
            entriesToRemove.push(entry)

        if entriesToRemove.length > 0
          for entry in entriesToRemove
            $(entry.node).remove()

          newEntries = _.reject(entries, (e) -> _.select(entriesToRemove, (ee) -> ee.css == e.css).length > 0)

          if newEntries.length == 0
            delete self.domMap[existingHash]
          else
            self.domMap[existingHash] = newEntries
      else
        if !seenCsses[entries.hash] ||
            (_.isArray(seenCsses[entries.hash]) && !_.include(seenCsses[entries.hash], entries.css)) ||
            (!_.isArray(seenCsses[entries.hash]) && seenCsses[entries.hash] != entries.css)

          $(entries.node).remove()
          delete self.domMap[existingHash]

