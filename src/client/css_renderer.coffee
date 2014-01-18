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

  update: (doc_id, newCss) ->
    parser = new less.Parser()
    self = this

    ruleSetToString = (ruleSet, m) ->
      return "" unless ruleSet.selectors && ruleSet.rules

      selectorCss = _.map(ruleSet.selectors, (s) ->
        _.each s.elements, (element) ->
          element.value = ".phork-html-body" if element.value == "body"
          element.value = "" if element.value == "html"

        ".phork-html #{s.toCSS()}"
      ).join(",")

      indent = if m then "    " else "  "

      rulesCss = _.map(ruleSet.rules, (rule) ->
        ruleCss = rule.toCSS({})

        # Bug where things are not quoted
        ruleCss = ruleCss.replace(/(local|url)\(([^'"][^)]+)\)/ig, "$1('$2')")
        "#{indent}#{ruleCss};"
      ).join("\n")

      css = selectorCss + "  {\n" + rulesCss + "\n}\n"
      css = "@media #{m.features.toCSS({})} {\n#{css}\n}" if m
      css

    parser.parse newCss || "", (err, tree) ->
      if err
        #console.log newCss
        #console.log err
        return

      seenCsses = {}
      currentMedia = null

      processLessNode = (n, index, m) ->
        if n.type == "Media"
          ((media) ->
            _.each n.rules[0].rules, (node) ->
              processLessNode(node, 0, media))(n)

          return
        else if n.type == "Directive"
          if n.name.toLowerCase() == "@font-face"
            css = "@font-face \n#{ruleSetToString(n.rules[0])}\n"
          else
            return
        else if n.type != "Ruleset"
          return
        else
          css = ruleSetToString(n, m)

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

      _.each tree.rules, ((n, index) -> processLessNode(n, index))

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

