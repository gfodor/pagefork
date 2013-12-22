class HtmlToJsxParser
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

  htmlToJsxString: (html) ->
    handler = new Tautologistics.NodeHtmlParser.HtmlBuilder (error, dom) ->
      if (error)
        console.log("error")

    new Tautologistics.NodeHtmlParser.Parser(handler).parseComplete(html)

    return this.domToJsxString(handler.dom)

  domToJsxString: (dom) ->
    jsx = ""
    css_parser = new less.Parser()

    cleanAttribute = (value) ->
      value.replace(/\"/g, "&quot;")

    walk = (node) ->
      if node.type == "tag"
        if React.DOM[node.name]
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
                  console.log("parse style " + value)

                  css_parser.parse ".class { #{value} }", (err, tree) ->
                    if err
                      console.log("css parse failed #{err}")
                    else
                      console.log(tree.rules[0].selectors[0])
                else
                  jsx += "#{name}=\"#{cleanAttribute(value)}\""
              else
                console.log("invalid attribute " + name)

          jsx += ">\n"

          if node.children?
            for child in node.children
              walk(child)

          jsx += "</#{node.name}>\n"
        else
          console.log("invalid tag #{node.name}")
      else if node.type == "text"
        jsx += node.data
      else
        console.log("invalid type " + node.type)

    for node in dom
      walk(node)

    console.log("parsed into #{jsx}")

    return jsx

window.HtmlToJsxParser = HtmlToJsxParser