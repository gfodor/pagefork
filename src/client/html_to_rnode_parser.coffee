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

  htmlToRNode: (html, previousBracketDiff, previousTagDiff) ->
    container = document.createElement('html')
    container.innerHTML = html
    this.rNodeFromNode($("body", container)[0], "rNodeRoot")

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
    return null if tag == "script" || tag == "noscript" || tag == "head"

    isTT = tag == "tt"
    isBody = tag == "body"
    isFont = tag == "font"

    rNodeAttributes = { key: rNodeKey }
    konstructor = (!isBody && React.DOM[tag]) || React.DOM.div

    styles = {}

    if isTT
      styles["font-family"] = "monospace"
    
    unless isFont
      for attribute in node.attributes
        attributeName = ATTRIBUTE_MAPPING[attribute.name] || attribute.name

        if attributeName == "style"
          for selector, value of this.parseStyles(attribute.value)
            styles[selector] = value
        else
          rNodeAttributes[attributeName] = attribute.value

      if _.keys(styles).length > 0
        rNodeAttributes.style = styles
    else
      for attribute in node.attributes
        if attribute.name == "face"
          styles["font-family"] = attribute.value
        else if attribute.name == "color"
          styles["color"] = attribute.value
        else if attribute.name == "size"
          styles["font-size"] = attribute.value

      rNodeAttributes.style = styles

    if isBody
      rNodeAttributes.className = "" unless rNodeAttributes.className?
      rNodeAttributes.className += " phork-html-body"

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
