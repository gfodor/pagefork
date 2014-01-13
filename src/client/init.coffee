$ ->
  docIds = []
  phorkId = $('body').data('phorkId')

  initDoc = (docInfo, sjs) ->
    doc = sjs.get('docs', docInfo.doc_id)
    doc.subscribe()

    doc.whenReady ->
      codeDiv = $("<div>").prop("id", "code-#{docInfo.doc_id}")
      textArea = $("<textarea>").val(doc.snapshot)
      codeDiv.append(textArea)
      $("#phork-ui .tabs").append(codeDiv)

      codeMirror = CodeMirror.fromTextArea(textArea[0], { mode: "text/#{docInfo.type}" })
      doc.attachCodeMirror(codeMirror)

      target = null
      component = null

      if docInfo.primary
        component = new HtmlRenderer(content: doc.snapshot)
        target = $("#doc-container .html")[0]
      else if docInfo.type == "css"
        cssDiv = $("<div>").prop("id", "content-#{docInfo.doc_id}")
        $("#doc-container .styles").append(cssDiv)
        target = cssDiv[0]
        component = new CssRenderer(content: doc.snapshot)

      if target && component
        codeMirror.on "change", (editor, change) ->
          component.setProps(content: editor.getValue())

        setTimeout((-> React.renderComponent(component, target)), 0)

  $.get "/phorks/#{phorkId}.json", dataType: "json", (res) ->
    socket = new BCSocket(null, {reconnect: true})
    sjs = new window.sharejs.Connection(socket)

    for docInfo in res.docs
      initDoc(docInfo, sjs)

