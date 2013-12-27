class HtmlToRNodeParser
  NODE_TYPE =
    ELEMENT: 1
    TEXT: 3
    COMMENT: 8

  ATTRIBUTE_MAPPING =
    for: "htmlFor"
    class: "className"

  htmlToRNode: (html) ->
    container = document.createElement('div')
    container.innerHTML = html

    this.rNodeFromNode(container, "rNodeRoot")

  cleanHtml: (html) ->
    html.trim().replace(/<script(.|\s)*<\/script>/gim, '').replace(/<noscript(.|\s)*<\/noscript>/gim, '')

  rNodeFromNode: (node, rNodeKey) ->
    switch node.nodeType
      when NODE_TYPE.ELEMENT
        this.elementRNodeFromNode(node, rNodeKey)
      when NODE_TYPE.TEXT
        node.textContent

  elementRNodeFromNode: (node, rNodeKey) ->
    tag = node.tagName.toLowerCase()
    return null if tag == "script" || tag == "noscript"

    rNodeAttributes = { key: rNodeKey }
    konstructor = React.DOM[tag] || React.DOM.div

    for attribute in node.attributes
      attributeName = ATTRIBUTE_MAPPING[attribute.name] || attribute.name

      if attributeName == "style"
        rNodeAttributes[attributeName] = this.parseStyles(attribute.value)
      else
        rNodeAttributes[attributeName] = attribute.value

    childrenRNodes = []

    for childNode in node.childNodes
      childRNode = this.rNodeFromNode(childNode, "rNode#{childrenRNodes.length}")
      childrenRNodes[childrenRNodes.length] = childRNode if childRNode

    new konstructor(rNodeAttributes, childrenRNodes)

  parseStyles: (rawStyle) ->
    styles = {}

    for style in rawStyle.split(";")
      style = style.trim()
      firstColon = style.indexOf(':')
      key = style.substr(0, firstColon)
      value = style.substr(firstColon + 1).trim()
      styles[key] = value unless key == ''

    styles


window.HtmlToRNodeParser = HtmlToRNodeParser
