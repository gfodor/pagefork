/**
  * @jsx React.DOM
  */

var JsxComponent = React.createClass({

  render: function() {
    return (new HtmlToRNodeParser()).htmlToRNode("<div>" + this.props.html + "</div>")
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
