window.HtmlRenderer = React.createClass
  render: ->
    (new HtmlToRNodeParser()).htmlToRNode("<div class=\"phork-html-body\">" + this.props.content + "</div>")
