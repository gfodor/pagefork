// Generated by CoffeeScript 1.5.0
(function() {
  var CssRenderer;

  window.CssRenderer = CssRenderer = (function() {

    function CssRenderer(el) {
      this.el = el;
      this.domMap = {};
    }

    CssRenderer.prototype.stringHash = function(st) {
      var char, hash, i, l, _i;
      hash = 0;
      l = st.length;
      if (l === 0) {
        return hash;
      }
      for (i = _i = 0; 0 <= l ? _i < l : _i > l; i = 0 <= l ? ++_i : --_i) {
        char = st.charCodeAt(i);
        hash = ((hash << 5) - hash) + char;
        hash |= 0;
      }
      return hash;
    };

    CssRenderer.prototype.update = function(doc_id, newCss) {
      var parser, ruleSetToString, self;
      ruleSetToString = function(r, index) {
        var rules, selector;
        if (!(r.selectors && r.rules)) {
          return "";
        }
        selector = _.map(r.selectors, function(s) {
          _.each(s.elements, function(element) {
            if (element.value === "body") {
              return element.value = ".phork-html-body";
            }
          });
          return s.toCSS();
        }).join(",");
        rules = _.map(r.rules, function(r) {
          return "  " + (r.toCSS({})) + ";";
        }).join("\n");
        return ".phork-html " + selector + " {\n" + rules + "\n}\n";
      };
      parser = new less.Parser();
      self = this;
      return parser.parse(newCss, function(err, tree) {
        var entries, entriesToRemove, entry, existingHash, newEntries, seenCsses, _i, _j, _k, _len, _len1, _len2, _ref, _results;
        if (err) {
          return;
        }
        seenCsses = {};
        _.each(tree.rules, function(r) {
          var candidateCurrentEntry, css, currentEntry, entries, hash, node, _i, _len;
          css = ruleSetToString(r);
          hash = self.stringHash(css);
          if (css === "") {
            return;
          }
          if (seenCsses[hash]) {
            if (!_.isArray(seenCsses[hash])) {
              seenCsses[hash] = [seenCsses[hash]];
            }
            seenCsses[hash].push(css);
          } else {
            seenCsses[hash] = css;
          }
          currentEntry = null;
          entries = self.domMap[hash];
          if (entries) {
            if (_.isArray(entries)) {
              for (_i = 0, _len = entries.length; _i < _len; _i++) {
                candidateCurrentEntry = entries[_i];
                if (candidateCurrentEntry.css === css) {
                  currentEntry = candidateCurrentEntry;
                }
              }
            } else {
              if (entries.css === css) {
                currentEntry = entries;
              }
            }
          }
          if (!currentEntry) {
            node = $("<style>").text(css);
            $(".phork-styles").append(node);
            if (entries) {
              if (!_.isArray(entries)) {
                entries = self.domMap[hash] = [entries];
              }
              return entries.push({
                hash: hash,
                css: css,
                node: node
              });
            } else {
              return self.domMap[hash] = {
                hash: hash,
                css: css,
                node: node
              };
            }
          }
        });
        _ref = _.keys(self.domMap);
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          existingHash = _ref[_i];
          entries = self.domMap[existingHash];
          if (_.isArray(entries)) {
            entriesToRemove = [];
            for (_j = 0, _len1 = entries.length; _j < _len1; _j++) {
              entry = entries[_j];
              if (seenCsses[entry.hash]) {
                if ((_.isArray(seenCsses[entry.hash]) && !_.include(seenCsses[entry.hash], entry.css)) || (!_.isArray(seenCsses[entry.hash]) && seenCsses[entry.hash] !== entry.css)) {
                  entriesToRemove.push(entry);
                }
              } else {
                entriesToRemove.push(entry);
              }
            }
            if (entriesToRemove.length > 0) {
              for (_k = 0, _len2 = entriesToRemove.length; _k < _len2; _k++) {
                entry = entriesToRemove[_k];
                $(entry.node).remove();
              }
              newEntries = _.reject(entries, function(e) {
                return _.select(entriesToRemove, function(ee) {
                  return ee.css === e.css;
                }).length > 0;
              });
              if (newEntries.length === 0) {
                _results.push(delete self.domMap[existingHash]);
              } else {
                _results.push(self.domMap[existingHash] = newEntries);
              }
            } else {
              _results.push(void 0);
            }
          } else {
            if (!seenCsses[entries.hash] || (_.isArray(seenCsses[entries.hash]) && !_.include(seenCsses[entries.hash], entries.css)) || (!_.isArray(seenCsses[entries.hash]) && seenCsses[entries.hash] !== entries.css)) {
              $(entries.node).remove();
              _results.push(delete self.domMap[existingHash]);
            } else {
              _results.push(void 0);
            }
          }
        }
        return _results;
      });
    };

    return CssRenderer;

  })();

}).call(this);