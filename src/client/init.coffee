$ ->
  phorkId = $('body').data('phorkId')
  readyDocs = 0
  totalDocs = 0
  htmlVersion = 0

  guardCount = 0
  guardFrame = null
  primaryComponent = null
  primaryAceEditor = null

  resetGuard = ->
    return if guardFrame && !guardFrame.isReady?

    $(".phork-guard").unbind("ready").remove()

    $guardFrame = $("<iframe>")
    $guardFrame.attr
      src: "/guard"
      class: "phork-guard"
      id: "phork-guard-#{guardCount++}"

    guardFrame = $guardFrame[0]
    $("body").append($guardFrame)

  resetGuard()

  updateDOMAfterGuard = ->
    if guardFrame && guardFrame.isReady?
      msg =
        beforeHtml: primaryComponent.props.content
        afterHtml: primaryAceEditor.getValue()
        version: ++htmlVersion

      guardFrame.contentWindow.postMessage(JSON.stringify(msg), "*")

  window.addEventListener "message", (e) ->
    data = JSON.parse(e.data)

    if data.type == "guard"
      if data.result
        if data.version == htmlVersion
          primaryComponent.setProps(content: data.afterHtml)
      else
        resetGuard()
    else if data.type == "guardReady"
      if guardFrame && e.source == guardFrame.contentWindow
        guardFrame.isReady = true

  initDoc = (docInfo, sjs) ->
    totalDocs += 1

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
        primaryComponent = new HtmlRenderer(content: doc.snapshot)
        primaryAceEditor = aceEditor

        aceEditor.getSession().on "change", (e) ->
          updateDOMAfterGuard()
          true

        readyDocs += 1

        showWhenReady = ->
          if readyDocs >= totalDocs
            setTimeout((->
              React.renderComponent primaryComponent, $("#doc-container .phork-html")[0]
            ), 0)
          else
            setTimeout(showWhenReady, 500)

        showWhenReady()
      else if docInfo.type == "css"
        component = new CssRenderer()

        setTimeout((->
          component.update(docInfo.doc_id, doc.snapshot)
          readyDocs += 1
        ), 0)

        aceEditor.getSession().on "change", (e) ->
          setTimeout((-> component.update(docInfo.doc_id, doc.snapshot)), 0)
          true

  $.get "/phorks/#{phorkId}.json", dataType: "json", (res) ->
    socket = new BCSocket(null, {reconnect: true})
    sjs = new window.sharejs.Connection(socket)

    for docInfo in res.docs
      initDoc(docInfo, sjs)

