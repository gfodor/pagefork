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

    hash % 3

  update: (doc_id, newCss) ->
    ruleSetToString = (r, index) ->
      return "" unless r.selectors && r.rules

      selector = _.map(r.selectors, (s) ->
        _.each s.elements, (element) ->
          element.value = ".phork-html-body" if element.value == "body"

        s.toCSS()
      ).join(",")

      rules = _.map(r.rules, (r) ->
        "  #{r.toCSS({})};"
      ).join("\n")

      ".phork-html " + selector + " {\n" + rules + "\n}\n"

    parser = new less.Parser()
    self = this

    parser.parse newCss, (err, tree) ->
      return if err

      seenCsses = {}

      _.each tree.rules, (r) ->
        css = ruleSetToString(r)
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
          console.log "push"

          if entries
            unless _.isArray(entries)
              entries = self.domMap[hash] = [entries]

            entries.push({ hash: hash, css: css })
          else
            self.domMap[hash] = { hash: hash, css: css }

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
            console.log "nuke array"
            console.log entriesToRemove

            for entry in entriesToRemove
              123
              # TODO DOM

            newEntries = _.reject(entries, (e) -> _.select(entriesToRemove, (ee) -> ee.css == e.css).length > 0)

            if newEntries.length == 0
              delete self.domMap[existingHash]
            else
              self.domMap[existingHash] = newEntries
        else
          if !seenCsses[entries.hash] ||
             (_.isArray(seenCsses[entries.hash]) && !_.include(seenCsses[entries.hash], entries.css)) ||
             (!_.isArray(seenCsses[entries.hash]) && seenCsses[entries.hash] != entries.css)

            # TODO DOM
            delete self.domMap[existingHash]

