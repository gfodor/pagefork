$ ->
  $("#loadEtsy").click (e) ->
    e.preventDefault()

    url = "http://localhost:8000/test_html_docs/etsy1.html"
    
    $.get url, (response) ->
      asset_package = (new HtmlAssetExtractor()).extract(response, "http://external.com", "myFork123")
      console.log(asset_package)

      #window.codeEditors.htmlEditor.setValue(asset_package.html)
      #window.codeEditors.cssEditor.setValue(asset_package.css)

    false

$ ->
  editorInfos = [
    { target: "#styles", mode: "text/css", editorSelector: "#cssEditor", component: CssRenderer },
    { target: "#html", mode: "text/html", editorSelector: "#htmlEditor", component: HtmlRenderer } 
  ]

  for editorInfo in editorInfos
    { target: target, mode: mode, editorSelector: editorSelector, component: component } = editorInfo

    codeMirror = CodeMirror.fromTextArea($(editorSelector)[0], { mode: mode })
    window.codeEditors ?= {}
    window.codeEditors[editorSelector.replace("#", "")] = codeMirror

    updateContent = (content) ->
      React.renderComponent(
        new component(content: content),
        $(target)[0])
    
    updateContent(codeMirror.getValue())

    codeMirror.on "change", (editor, change) ->
      updateContent(editor.getValue())
