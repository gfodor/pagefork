$ ->
  phorkId = $('body').data('phorkId')
  readyDocs = 0
  totalDocs = 0

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
        component = new HtmlRenderer(content: doc.snapshot)

        target = $("#doc-container .phork-html")[0]
        testComponent = null
        testCount = 0

        resetTest = ->
          testComponent.unmountComponent() if testComponent

          ((id) -> setTimeout((-> $(id).remove()), 0))("#phork-test-#{testCount}")

          testTargetSel = $("<div>").addClass("phork-html-test").attr("id", "phork-test-#{++testCount}")
          $("#doc-container").append(testTargetSel)
          testComponent = new HtmlRenderer content: "<div>hello</div>"
          React.renderComponent(testComponent, testTargetSel[0])

        aceEditor.getSession().on "change", (e) ->
          f = ->
            try
              html = aceEditor.getValue()
              #testComponent.setProps content: html
              console.log "ok"
              component.setProps content: html
            catch e
              console.log(" stop")
              console.log(e.stack)
              component.forceUpdate()
              #setTimeout((-> resetTest()), 0)

          setTimeout(f, 0)

          true

        readyDocs += 1

        showWhenReady = ->
          if readyDocs >= totalDocs
            React.renderComponent(component, target)
            resetTest()
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

        #  cssDiv = $("<div>").prop("id", "content-#{docInfo.doc_id}")
        #  $("#doc-container .rendered-source-styles").append(cssDiv)
        #  target = cssDiv[0]
        #  component = new CssRenderer(content: doc.snapshot)

  $.get "/phorks/#{phorkId}.json", dataType: "json", (res) ->
    socket = new BCSocket(null, {reconnect: true})
    sjs = new window.sharejs.Connection(socket)

    for docInfo in res.docs
      initDoc(docInfo, sjs)

