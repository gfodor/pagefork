chrome.runtime.onConnect.addListener (conn) ->
  console.log "connected"
  console.log conn

  chrome.runtime.onMessage.addListener (message, sender, sendResponse) ->
    console.log message


chrome.browserAction.onClicked.addListener (tab) ->
  chrome.pageCapture.saveAsMHTML { tabId: tab.id }, (mhtml) ->
    host = "http://localhost:3000"

    reader = new FileReader()
    reader.addEventListener "loadend", ->
      payload = { mhtml: reader.result }

      $.get "#{host}/phorks/new", { }, (response) ->
        mhtml_url = response.mhtml_url
        phork_id = response.phork_id

        $.ajax type: "PUT", contentType: "multipart/related", url: mhtml_url, data: payload.mhtml.toString(), success: (response) ->
          $.post "#{host}/phorks", { phork_id: phork_id }, (response) ->
            chrome.tabs.executeScript code: "document.location = '#{host}/phorks/#{phork_id}';"

    reader.readAsText(mhtml)
