window.HtmlRenderer = React.createClass
  render: ->
    parser = new HtmlToRNodeParser()

    this.bracketDiff ?= parser.getBracketDiff(this.props.content)
    this.tagDiff ?= parser.getTagDiff(this.props.content)
    newRNode = parser.htmlToRNode(this.props.content, this.bracketDiff, this.tagDiff)

    this.reactRootNode = newRNode if newRNode
    this.reactRootNode


