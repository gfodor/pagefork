class HtmlToJsxParser
  htmlToJsxString: (html) ->
    handler = new Tautologistics.NodeHtmlParser.HtmlBuilder (error, dom) ->
      if (error)
        console.log("error")

    new Tautologistics.NodeHtmlParser.Parser(handler).parseComplete(html)

    return this.domToJsxString(handler.dom)

  domToJsxString: (dom) ->
    jsx = ""
    styles = {}

    css_parser = new less.Parser()

    cleanAttribute = (value) ->
      value.replace(/\"/g, "&quot;")

    walk = (node) ->
      if node.type == "tag"
        if React.DOM[node.name] && node.name.toLowerCase() != "script"
          jsx += "<#{node.name} "

          if node.attributes
            for name, value of node.attributes
              name = name.toLowerCase()

              if name == "class"
                name = "classname"

              reactName = validReactProperties[name]
              name = reactName if reactName

              if reactName or
                 name.indexOf("data-") == 0 or
                 name.indexOf("aria-") == 0

                if name == "style"
                  css_parser.parse ".class { #{value} }", (err, tree) ->
                    if err
                      #console.log("css parse failed #{err}")
                    else
                      generatedClass = "jsxGen#{Math.floor(Math.random() * 10000000)}"

                      css = {}

                      for rule in tree.rules[0].rules
                        css[rule.name] = rule.value.toCSS()

                      styles[generatedClass] = css

                      jsx += "style={#{generatedClass}}"
                else
                  if value
                    jsx += " #{name}=\"#{cleanAttribute(value)}\" "
                  else
                    jsx += " #{name} "
              else
                #console.log("invalid attribute " + name)

          jsx += ">\n"

          if node.children?
            for child in node.children
              walk(child)

          jsx += "</#{node.name}>\n"
        else
          #console.log("invalid tag #{node.name}")
      else if node.type == "text"
        text = node.data.trim()
        text = text.replace(/&nbsp;/, " ") # React BUG?
        text = text.replace(/&#160;/, " ") # React BUG?

        jsx += text
      else
        unless node.type == "comment"
          console.log("invalid type " + node.type)

    for node in dom
      walk(node)

    styleScript = ""

    for className, css of styles
      styleScript += "var #{className} = #{JSON.stringify(css)};\n"

    line_num = 1

    #for line in jsx.split("\n")
    #  console.log "#{line_num} #{line}"
    #  line_num += 1

    jsx = "<div>#{jsx}</div>"

    return { jsx: jsx, styleScript: styleScript }

  validReactProperties = {
    accept: "accept",
    accesskey: "accessKey",
    action: "action",
    allowfullscreen: "allowFullScreen",
    allowtransparency: "allowTransparency",
    alt: "alt",
    async: "async",
    autocomplete: "autoComplete",
    autofocus: "autoFocus",
    autoplay: "autoPlay",
    cellpadding: "cellPadding",
    cellspacing: "cellSpacing",
    charset: "charSet",
    checked: "checked",
    classname: "className",
    cols: "cols",
    colspan: "colSpan",
    content: "content",
    contenteditable: "contentEditable",
    contextmenu: "contextMenu",
    controls: "controls",
    data: "data",
    datetime: "dateTime",
    defer: "defer",
    dir: "dir",
    disabled: "disabled",
    draggable: "draggable",
    enctype: "encType",
    form: "form",
    frameborder: "frameBorder",
    height: "height",
    hidden: "hidden",
    href: "href",
    htmlfor: "htmlFor",
    httpequiv: "httpEquiv",
    icon: "icon",
    id: "id",
    label: "label",
    lang: "lang",
    list: "list",
    loop: "loop",
    max: "max",
    maxlength: "maxLength",
    method: "method",
    min: "min",
    multiple: "multiple",
    name: "name",
    pattern: "pattern",
    placeholder: "placeholder",
    poster: "poster",
    preload: "preload",
    radiogroup: "radioGroup",
    readonly: "readOnly",
    rel: "rel",
    required: "required",
    role: "role",
    rows: "rows",
    rowspan: "rowSpan",
    scrollleft: "scrollLeft",
    scrolltop: "scrollTop",
    selected: "selected",
    size: "size",
    spellcheck: "spellCheck",
    src: "src",
    step: "step",
    style: "style",
    tabindex: "tabIndex",
    target: "target",
    title: "title",
    type: "type",
    value: "value",
    width: "width",
    wmode: "wmode",
  }


window.HtmlToJsxParser = HtmlToJsxParser
