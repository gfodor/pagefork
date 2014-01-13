/**
  * @jsx React.DOM
  */

var HtmlRenderer = React.createClass({
  render: function() {
    rnode = (new HtmlToRNodeParser()).htmlToRNode("<div>" + this.props.content + "</div>")

    return rnode;
  },
});

var CssRenderer = React.createClass({
  render: function() {
    if (this.props.content) {
      var parser = new less.Parser();
      var ret = null;

      var ruleSetToString = function(r) {
        if (!r.selectors || !r.rules) {
          return "";
        }

        var selector = r.selectors.map(function(s) { 
          _.each(s.elements, function(element) { 
            if (element.value == "body") {
              element.value = ".rendered-source-html";
            }
          });

          return s.toCSS(); 
        }).join(" ");

        var rules = r.rules.map(function(r) { return "  " + r.toCSS({}); }).join("\n");
        return selector + " {\n" + rules + "\n}\n";
      };

      parser.parse(this.props.content, function(err, tree) {
        if (err) {
          ret = (
            <div></div>
          );
        } else {
          ret = (
            <div>
              {tree.rules.map(function(r) {
                return (
                  <style key={"rule_" + tree.rules.indexOf(r)}>
                    {ruleSetToString(r)}
                  </style>
                );
              })}
            </div>
          );
        }
      });

      return ret;
    } else {
      return (
        <div/>
      );
    }
  }
});
