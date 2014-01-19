$ ->
  target = $("#doc-container .phork-html")[0]
  component = new HtmlRenderer(content: "<div></div>")
  React.renderComponent component, target

  window.addEventListener "message", (e) ->
    data = JSON.parse(e.data)

    ok = false

    try
      if component.props.content != data.beforeHtml
        component.setProps(content: data.beforeHtml)

      component.setProps(content: data.afterHtml)
      ok = true
    catch e

    response =
      type: "guard"
      result: ok
      version: data.version
      afterHtml: data.afterHtml

    e.source.postMessage(JSON.stringify(response), "*")

  window.parent.postMessage(JSON.stringify(type: "guardReady", result: true), "*")
