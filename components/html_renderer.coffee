window.HtmlRenderer = React.createClass
  render: ->
    (new HtmlToRNodeParser()).htmlToRNode("<div>" + this.props.content + "</div>")
