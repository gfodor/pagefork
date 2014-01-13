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

      target = null
      component = null

      if docInfo.primary
        component = new HtmlRenderer(content: doc.snapshot)
        target = $("#doc-container .rendered-source-html")[0]
      else if docInfo.type == "css"
        cssDiv = $("<div>").prop("id", "content-#{docInfo.doc_id}")
        $("#doc-container .rendered-source-styles").append(cssDiv)
        target = cssDiv[0]
        component = new CssRenderer(content: doc.snapshot)

      if target && component
        aceEditor.getSession().on "change", (e) ->
          component.setProps(content: aceEditor.getValue())
          true

        delay = if docInfo.primary then 5000 else 0
        setTimeout((-> React.renderComponent(component, target)), delay)

  $.get "/phorks/#{phorkId}.json", dataType: "json", (res) ->
    socket = new BCSocket(null, {reconnect: true})
    sjs = new window.sharejs.Connection(socket)

    for docInfo in res.docs
      initDoc(docInfo, sjs)

