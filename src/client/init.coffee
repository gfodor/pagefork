$ ->
  docIds = []
  phorkId = $('body').data('phorkId')

  $.get "/phorks/#{phorkId}.json", dataType: "json", (res) ->
    socket = new BCSocket(null, {reconnect: true})
    sjs = new window.sharejs.Connection(socket)

    for docInfo in res.docs
      console.log docInfo
      if docInfo.primary
        doc = sjs.get('docs', docInfo.doc_id)
        doc.subscribe()

        doc.whenReady ->
          doc.attachTextarea($("#htmlEditor")[0])
      #if (!doc.type) doc.create('text')
      #if (doc.type && doc.type.name === 'text')
      #  doc.attachTextarea(elem)

#  editorInfos = [
#    { target: "#styles", mode: "text/css", editorSelector: "#cssEditor", component: CssRenderer },
#    { target: "#html", mode: "text/html", editorSelector: "#htmlEditor", component: HtmlRenderer }
#  ]
#
#  for editorInfo in editorInfos
#    ((editorInfo) ->
#      { target: target, mode: mode, editorSelector: editorSelector, component: component } = editorInfo
#
#      codeMirror = CodeMirror.fromTextArea($(editorSelector)[0], { mode: mode })
#      window.codeEditors ?= {}
#      window.codeEditors[editorSelector.replace("#", "")] = codeMirror
#
#      updateContent = (content) ->
#        React.renderComponent(
#          new component(content: content),
#          $(target)[0])
#      
#      updateContent(codeMirror.getValue())
#
#      codeMirror.on "change", (editor, change) ->
#        updateContent(editor.getValue()))(editorInfo)
