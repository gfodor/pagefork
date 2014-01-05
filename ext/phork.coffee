chrome.browserAction.onClicked.addListener (tab) ->
  chrome.pageCapture.saveAsMHTML { tabId: tab.id }, (mhtml) ->
    reader = new FileReader()
    reader.addEventListener "loadend", ->
      payload = { mhtml: reader.result }

      $.get "http://localhost:3000/phorks/new", JSON.stringify(payload), (response) ->
        mhtml_url = response.mhtml_url

        $.ajax type: "PUT", contentType: "multipart/related", url: mhtml_url, data: payload.mhtml.toString(), success: (response) ->
          console.log(response)

    reader.readAsText(mhtml)
