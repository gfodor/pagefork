window.HtmlRenderer = React.createClass
  render: ->
    parser = new HtmlToRNodeParser()
    parser.htmlToRNode(this.props.content)


