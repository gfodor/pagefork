$ ->
  phorkId = $('body').data('phorkId')
  readyDocs = {}
  totalDocs = 0
  htmlVersion = 0

  guardCount = 0
  guardFrame = null
  styFrames = {}
  readyStyFrames = {}
  primaryComponent = null
  components = {}
  primaryAceEditor = null
  docUpdateTimeouts = {}
  docReflowTimeouts = {}

  reflow = ->
    content = primaryComponent.props.content
    s = $(window).scrollTop()
    primaryComponent.setProps(content: "<div></div>")
    primaryComponent.setProps(content: content)
    $(window).scrollTop(s)

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

  afterHelperFramesReady = (docInfo, cb) ->
    if docInfo.type == "css"
      styframe = $("<iframe>")
      styframe.attr
        src: "/styframe"
        class: "phork-styframe"
        id: "phork-styframe-#{docInfo.doc_id}"

      styframe.ready ->
        readyStyFrames[docInfo.doc_id] = true

      styFrames[docInfo.doc_id] = styframe[0]

      $("body").append(styframe)

      waitForStyFrame = ->
        if readyStyFrames[docInfo.doc_id]
          cb()
        else
          setTimeout(waitForStyFrame, 100)

      waitForStyFrame()
    else
      cb()

  initDoc = (docInfo, sjs) ->
    totalDocs += 1

    afterHelperFramesReady docInfo, ->
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
          initPrimaryDoc(docInfo, doc, aceEditor)
        else if docInfo.type == "css"
          initCssDoc(docInfo, doc, aceEditor)

        true

  initPrimaryDoc = (docInfo, doc, aceEditor) ->
    primaryComponent = new HtmlRenderer(content: doc.snapshot)
    components[docInfo.doc_id] = primaryComponent
    primaryAceEditor = aceEditor

    aceEditor.getSession().on "change", (e) ->
      updateTimeout = docUpdateTimeouts[docInfo.doc_id]
      clearTimeout(updateTimeout) if updateTimeout
      docUpdateTimeouts[docInfo.doc_id] = setTimeout(updateDOMAfterGuard, 250)

      reflowTimeout = docReflowTimeouts[docInfo.doc_id]
      clearTimeout(reflowTimeout) if reflowTimeout
      docReflowTimeouts[docInfo.doc_id] = setTimeout(reflow, 2500)
      true

    readyDocs[docInfo.doc_id] = true

    showWhenAllDocsReady = ->
      if _.keys(readyDocs).length >= totalDocs
        setTimeout((->
          React.renderComponent primaryComponent, $("#doc-container .phork-html")[0]
        ), 0)
      else
        setTimeout(showWhenAllDocsReady, 100)

    showWhenAllDocsReady()

  initCssDoc = (docInfo, doc, aceEditor) ->
    styleContainer = $("<div>").attr("id", "styles-#{docInfo.doc_id}")[0]
    $(".phork-styles").append(styleContainer)

    component = new CssRenderer(styleContainer)
    components[docInfo.doc_id] = component

    updateCssViaStyframe = (css, doc_id) ->
      $("style", $(styFrames[doc_id].contentWindow.document)).html(css)
      styleSheet = styFrames[doc_id].contentWindow.document.styleSheets[0]
      console.log styleSheet

      component = components[doc_id]
      component.update(doc_id, styleSheet)

    ((component, docInfo, doc) -> setTimeout((->
      updateCssViaStyframe(doc.snapshot, docInfo.doc_id)
      readyDocs[docInfo.doc_id] = true
    ), 0))(component, docInfo, doc)

    aceEditor.getSession().on "change", (e) ->
      updateTimeout = docUpdateTimeouts[docInfo.doc_id]
      clearTimeout(updateTimeout) if updateTimeout

      docUpdateTimeouts[docInfo.doc_id] = setTimeout(((component, docInfo, doc) -> (->
        updateCssViaStyframe(aceEditor.getValue(), docInfo.doc_id)
      ))(component, docInfo, doc), 250)

      true

  $.get "/phorks/#{phorkId}.json", dataType: "json", (res) ->
    socket = new BCSocket(null, {reconnect: true})
    sjs = new window.sharejs.Connection(socket)

    for docInfo in res.docs
      initDoc(docInfo, sjs)

