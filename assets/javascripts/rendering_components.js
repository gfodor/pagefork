/**
  * @jsx React.DOM
  */

var HtmlRenderer = React.createClass({
  render: function() {
    var container = document.createElement('html')
    container.innerHTML = this.props.content

    var newBody = $("body", container);

    if (newBody.length == 0) {
      newBody = $(container);
    }

    rnode = (new HtmlToRNodeParser()).htmlToRNode("<div>" + newBody.html() + "</div>")

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

        var selector = r.selectors.map(function(s) { return s.toCSS(); }).join(" ");
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
