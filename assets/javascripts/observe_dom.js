// Generated by CoffeeScript 1.5.0
(function() {

  window.observeDOM = function(obj, callback) {
    var MutationObserver, obs;
    MutationObserver = window.MutationObserver || window.WebKitMutationObserver;
    if (MutationObserver) {
      obs = new MutationObserver(function(mutations, observer) {
        if (mutations.length > 0) {
          return callback();
        }
      });
      return obs.observe(obj, {
        childList: true,
        subtree: true,
        attributes: true
      });
    }
  };

}).call(this);