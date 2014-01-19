$ ->
  window.parent.postMessage(JSON.stringify({ type: "styframeReady" }), "*")
