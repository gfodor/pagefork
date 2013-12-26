/**
  * @jsx React.DOM
  */

var JsxComponent = React.createClass({

  render: function() {
    var converter = new HTMLtoJSX({ createClass: false })
    var jsx = "<div/>";

    console.log("1")
    if (this.props.html.trim().length > 0) {
      var parsedJsx = converter.convert(this.props.html);

      if (parsedJsx.trim().length > 0) {
        jsx = parsedJsx;
      }
    }
    console.log("2")
    
    try {
      JSXTransformer.run("/**\n  * @jsx React.DOM\n   */\nwindow._renderedJSX = (\n" + jsx + "\n)")
    } catch (e) {
      console.log(e)
    }
    console.log("3")

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
