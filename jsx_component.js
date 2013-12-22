/**
  * @jsx React.DOM
  */

var JsxComponent = React.createClass({

  render: function() {
    var result = new HtmlToJsxParser().htmlToJsxString(this.props.html);
    var jsx = result.jsx;
    var styleScript = result.styleScript;

    JSXTransformer.run("/**\n  * @jsx React.DOM\n   */\n" + styleScript + "\nwindow._renderedJSX = (\n" + jsx + "\n)")

    return window._renderedJSX;
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
