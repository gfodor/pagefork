chrome.browserAction.onClicked.addListener (tab) ->
  # TODO wait until tab ready, don't let click twice
  chrome.pageCapture.saveAsMHTML { tabId: tab.id }, (mhtml) ->
    host = "http://localhost:3000"

    reader = new FileReader()
    
    reader.addEventListener "loadend", ->
      arr = Array.prototype.map.call reader.result.toString(), (c) ->
        c.charCodeAt(0)

      payload = ""
      payload += String.fromCharCode(c) for c in deflate(arr)

      $.get "#{host}/phorks/new", { }, (response) ->
        mhtml_url = response.mhtml_url
        phork_id = response.phork_id

        $.ajax type: "PUT", contentType: "multipart/related", url: mhtml_url, data: payload, success: (response) ->
          $.post "#{host}/phorks", { phork_id: phork_id }, (response) ->
            chrome.tabs.executeScript code: "document.location = '#{host}/phorks/#{phork_id}';"

    reader.readAsText(mhtml)
