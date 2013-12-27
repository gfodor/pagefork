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
  }
});

var JsxEditor = React.createClass({
  getInitialState: function() { 
    return { value: "<div class=\"some-class\" style=\"background-color: red\">Hi</div>" };
  },

  handleJSXTextChange: function(event) {
    this.setState({ value: event.target.value });
  },

  render: function() {
    var value = this.state.value;

    return (
      <div>
        <JsxComponent html={value}/>
        <textarea rows="25" cols="80" onChange={this.handleJSXTextChange}>{value}</textarea>
      </div>
    );
  }
});


React.renderComponent(
  <JsxEditor />,
  document.getElementById('content')
);
