class HtmlToRNodeParser
  NODE_TYPE =
    ELEMENT: 1
    TEXT: 3
    COMMENT: 8

  ATTRIBUTE_MAPPING =
    for: "htmlFor"
    class: "className"
    frameborder: "frameBorder"
    cellpadding: "cellPadding"
    cellspacing: "cellSpacing"
    colspan: "colSpan"
    tabindex: "tabIndex"
    autocomplete: "autoComplete"
    maxlength: "maxLength"
    autocorrect: "autoCorrect"
    autocapitalize: "autoCapitalize"

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
        if node.textContent.trim().length > 0
          React.DOM.text({}, node.textContent)
        else
          null

  elementRNodeFromNode: (node, rNodeKey) ->
    tag = node.tagName.toLowerCase()
    return null if tag == "script" || tag == "noscript"

    rNodeAttributes = { key: rNodeKey }
    konstructor = React.DOM[tag] || React.DOM.div
    styles = {}
    
    for attribute in node.attributes
      attributeName = ATTRIBUTE_MAPPING[attribute.name] || attribute.name

      if attributeName == "style"
        for selector, value of this.parseStyles(attribute.value)
          styles[selector] = value
      else if attributeName == "bgcolor"
        styles["background-color"] = attribute.value
      else if attributeName == "fgcolor"
        styles["color"] = attribute.value
      else if attributeName == "align"
        styles["text-align"] = attribute.value
      else if attributeName == "valign"
        styles["vertical-align"] = attribute.value
      else
        rNodeAttributes[attributeName] = attribute.value

    if _.keys(styles).length > 0
      rNodeAttributes.style = styles

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
