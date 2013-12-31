chrome.browserAction.onClicked.addListener (tab) ->
  chrome.pageCapture.saveAsMHTML { tabId: tab.id }, (mhtml) ->
    reader = new FileReader()
    reader.addEventListener "loadend", ->
      payload = { mhtml: reader.result }

      $.post "https://phork.io/phorks", JSON.stringify(payload), (response) ->
        console.log("OK")

    reader.readAsText(mhtml)
