$ ->
  docIds = []
  phorkId = $('body').data('phorkId')

  initDoc = (docInfo, sjs) ->
    doc = sjs.get('docs', docInfo.doc_id)
    doc.subscribe()

    doc.whenReady ->
      codeDiv = $("<div>").prop("id", "code-#{docInfo.doc_id}")
      editor = $("<div>")
      codeDiv.append(editor)
      $("#phork-ui .tabs").append(codeDiv)

      aceEditor = ace.edit("code-#{docInfo.doc_id}")
      $("#code-#{docInfo.doc_id}").addClass("code-editor")
      aceEditor.getSession().setMode("ace/mode/#{docInfo.type}")
      aceEditor.setTheme("ace/theme/monokai")
      doc.attach_ace(aceEditor)

      if docInfo.primary
        component = new HtmlRenderer(content: doc.snapshot)
        target = $("#doc-container .phork-html")[0]

        aceEditor.getSession().on "change", (e) ->
          setTimeout((-> component.setProps(content: aceEditor.getValue())), 0)
          true

        setTimeout((-> React.renderComponent(component, target)), 0)
      else if docInfo.type == "css"
        component = new CssRenderer()
        setTimeout((-> component.update(docInfo.doc_id, doc.snapshot)), 0)

        aceEditor.getSession().on "change", (e) ->
          setTimeout((-> component.update(docInfo.doc_id, doc.snapshot)), 0)
          true

        #  cssDiv = $("<div>").prop("id", "content-#{docInfo.doc_id}")
        #  $("#doc-container .rendered-source-styles").append(cssDiv)
        #  target = cssDiv[0]
        #  component = new CssRenderer(content: doc.snapshot)

  $.get "/phorks/#{phorkId}.json", dataType: "json", (res) ->
    socket = new BCSocket(null, {reconnect: true})
    sjs = new window.sharejs.Connection(socket)

    for docInfo in res.docs
      initDoc(docInfo, sjs)

