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
    html = html.replace(/<\s*html/gi, "<phork-html")
    html = html.replace(/<\/html/gi, "</phork-html")
    html = html.replace(/<\s*body/gi, "<phork-body")
    html = html.replace(/<\/body/gi, "</phork-body")

    container.innerHTML = html

    this.rNodeFromNode($(container)[0], "rNodeRoot")

  cleanHtml: (html) ->
    html.trim().replace(/<script(.|\s)*<\/script>/gim, '').replace(/<noscript(.|\s)*<\/noscript>/gim, '')

  rNodeFromNode: (node, rNodeKey) ->
    switch node.nodeType
      when NODE_TYPE.ELEMENT
        this.elementRNodeFromNode(node, rNodeKey)
      when NODE_TYPE.TEXT
        if node.textContent.trim().length > 0
          React.DOM.text({}, node.textContent.trim())
        else
          null

  elementRNodeFromNode: (node, rNodeKey, isRoot) ->
    tag = node.tagName.toLowerCase()
    return null if tag == "script" || tag == "noscript" || tag == "head"

    isTT = tag == "tt"
    isBody = tag == "phork-body"
    isHtml = tag == "phork-html"
    isFont = tag == "font"

    rNodeAttributes = { key: rNodeKey }
    konstructor = (!isBody && !isHtml && React.DOM[tag]) || React.DOM.div

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
          sizes =
            "-3": "x-small"
            "-2": "x-small"
            "-1": "small"
            "0": "x-small"
            "1": "x-small"
            "2": "small"
            "3": "medium"
            "4": "large"
            "5": "x-large"
            "6": "xx-large"
            "+0": "medium"
            "+1": "large"
            "+2": "x-large"
            "+3": "xx-large"
            "+4": "-webkit-xxx-large"
            "+5": "-webkit-xxx-large"
            "+6": "-webkit-xxx-large"
            "+7": "-webkit-xxx-large"

          if sizes[attribute.value]
            styles["font-size"] = sizes[attribute.value]
          else
            styles["font-size"] = attribute.value

      rNodeAttributes.style = styles

    if isHtml
      rNodeAttributes.className = "" unless rNodeAttributes.className?
      rNodeAttributes.className += " phork-html"
    else if isBody
      rNodeAttributes.className = "" unless rNodeAttributes.className?
      rNodeAttributes.className += " phork-body"

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
