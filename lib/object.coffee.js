(function() {
  var Object;

  Object = (function() {
    function Object() {}

    Object.prototype.version = function() {
      return 1;
    };

    Object.prototype.snapshot = function() {
      return _.clone(this);
    };

    Object.prototype.applySnapshot = function(snapshot) {
      var k, target, v, _results;

      _results = [];
      for (v in snapshot) {
        k = snapshot[v];
        _results.push(target = this[k]);
      }
      return _results;
    };

    return Object;

  })();

}).call(this);
