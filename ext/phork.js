// Generated by CoffeeScript 1.4.0
(function() {

  chrome.browserAction.onClicked.addListener(function(tab) {
    return chrome.pageCapture.saveAsMHTML({
      tabId: tab.id
    }, function(mhtml) {
      var host, reader;
      host = "http://localhost:3000";
      reader = new FileReader();
      reader.addEventListener("loadend", function() {
        var payload;
        payload = {
          mhtml: reader.result
        };
        return $.get("" + host + "/phorks/new", {}, function(response) {
          var mhtml_url, phork_id;
          mhtml_url = response.mhtml_url;
          phork_id = response.phork_id;
          return $.ajax({
            type: "PUT",
            contentType: "multipart/related",
            url: mhtml_url,
            data: payload.mhtml.toString(),
            success: function(response) {
              return $.post("" + host + "/phorks", {
                phork_id: phork_id
              }, function(response) {
                return console.log(response);
              });
            }
          });
        });
      });
      return reader.readAsText(mhtml);
    });
  });

}).call(this);
