/**
  * @jsx React.DOM
  */

var HtmlRenderer = React.createClass({
  render: function() {
    asset_package = (new HtmlAssetExtractor()).extract(this.props.content, "http://external.com", "myFork123")

    assets = asset_package.assets
    html = asset_package.html

    rnode = (new HtmlToRNodeParser()).htmlToRNode("<div>" + html + "</div>")

    return rnode;
  },
});

var CssRenderer = React.createClass({
  render: function() {
    if (this.props.content) {
      var parser = new less.Parser();
      var ret = null;

      var ruleSetToString = function(r) {
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
