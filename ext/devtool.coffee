conn = chrome.runtime.connect()

conn.onMessage.addListener (message) ->
  chrome.runtime.sendMessage "pong"

chrome.devtools.inspectedWindow.onResourceContentCommitted.addListener (resource, content) ->
  chrome.runtime.sendMessage { url: resource.url, content: content }

chrome.devtools.inspectedWindow.onResourceAdded.addListener (resource) ->
  chrome.runtime.sendMessage { url: "ADD: #{resource.url}" }
