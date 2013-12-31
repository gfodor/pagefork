window.observeDOM = (obj, callback) ->
  MutationObserver = window.MutationObserver || window.WebKitMutationObserver

  if MutationObserver
    obs = new MutationObserver (mutations, observer) ->
      if mutations.length > 0
        callback()

    obs.observe(obj, { childList:true, subtree:true, attributes: true })
