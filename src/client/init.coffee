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
        aceEditor.getSession().on "change", (e) ->
          component = new HtmlRenderer(content: aceEditor.getValue())

          try
            React.renderComponentToString component, (html) ->
              $("#doc-container .phork-html").html(html)
          catch e

          true

        readyDocs += 1

        showWhenReady = ->
          if readyDocs >= totalDocs
            setTimeout((->
              component = new HtmlRenderer(content: doc.snapshot)

              try
                React.renderComponentToString component, (html) ->
                  $("#doc-container .phork-html").html(html)
              catch e
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

        #  cssDiv = $("<div>").prop("id", "content-#{docInfo.doc_id}")
        #  $("#doc-container .rendered-source-styles").append(cssDiv)
        #  target = cssDiv[0]
        #  component = new CssRenderer(content: doc.snapshot)

  $.get "/phorks/#{phorkId}.json", dataType: "json", (res) ->
    socket = new BCSocket(null, {reconnect: true})
    sjs = new window.sharejs.Connection(socket)

    for docInfo in res.docs
      initDoc(docInfo, sjs)

