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

var JsxEditor = React.createClass({
  getInitialState: function() { 
    initialHtml = "<div class=\"some-class\" style=\"background-color: red\">Hi</div>";
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
          <textarea rows="25" cols="80" onChange={this.handleHtmlChange} value={html}/>
        </p>
      </div>
    );
  },
});


React.renderComponent(
  <JsxEditor />,
  document.getElementById('content')
);

