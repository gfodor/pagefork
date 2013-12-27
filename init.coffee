$ ->
  editorInfos = [
    { target: "#styles", mode: "text/css", editor: "#cssEditor", component: CssRenderer },
    { target: "#html", mode: "text/html", editor: "#htmlEditor", component: HtmlRenderer } 
  ]

  for editorInfo in editorInfos
    { target: target, mode: mode, editor: editor, component: component } = editorInfo

    #asset_package = (new HtmlAssetExtractor()).extract(this.props.content, "http://external.com", "myFork123")

    codeMirror = CodeMirror.fromTextArea($(editor)[0], { mode: mode })

    updateContent = (content) ->
      React.renderComponent(
        new component(content: content),
        $(target)[0])
    
    updateContent(codeMirror.getValue())

    codeMirror.on "change", (editor, change) ->
      updateContent(editor.getValue())
