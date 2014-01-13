window.HtmlRenderer = React.createClass
  render: ->
    (new HtmlToRNodeParser()).htmlToRNode(this.props.content)
