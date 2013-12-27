/**
  * @jsx React.DOM
  */

var JsxComponent = React.createClass({
  render: function() {
    asset_package = (new HtmlAssetExtractor()).extract(this.props.html, "http://external.com", "myFork123")

    assets = asset_package.assets
    html = asset_package.html

    rnode = (new HtmlToRNodeParser()).htmlToRNode("<div>" + html + "</div>")

    return rnode;
  },
});

var CssStyles = React.createClass({
  render: function() {
    if (this.props.css) {
      var parser = new less.Parser();
      var ret = null;

      var ruleSetToString = function(r) {
        var selector = r.selectors.map(function(s) { return s.toCSS(); }).join(" ");
        var rules = r.rules.map(function(r) { return "  " + r.toCSS({}); }).join("\n");
        return selector + " {\n" + rules + "\n}\n";
      };

      parser.parse(this.props.css, function(err, tree) {
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

var JsxEditor = React.createClass({
  getInitialState: function() { 
    initialHtml = "<div class=\"foo\">Hi</div>";
    return { sourceHtml: initialHtml, html: initialHtml };
  },
  
  handleSourceHtmlChange: function(event) {
    this.setState({ html: event.target.value, sourceHtml: event.target.value });
  },

  handleHtmlChange: function(event) {
    this.setState({ html: event.target.value });
  },

  render: function() {
    var html = this.state.html;
    var sourceHtml = this.state.sourceHtml;

    return (
      <div>
        <JsxComponent html={html}/>
        <p>
          source:
          <textarea rows="5" cols="80" onChange={this.handleSourceHtmlChange} value={sourceHtml}/>
        </p>
        <p>
          target:
          <textarea rows="5" cols="80" onChange={this.handleHtmlChange} value={html}/>
        </p>
      </div>
    );
  },
});
