(function() {
  var Child, Object, target,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  Object = (function() {
    function Object(engine) {
      this.engine = engine;
    }

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

    Object.prototype.upgrade = function(from) {
      console.log('upgraded from', from);
      console.log("HI hello");
      return console.log('this is the live coding');
    };

    return Object;

  })();

  Child = (function(_super) {
    __extends(Child, _super);

    function Child(engine, hello) {
      this.engine = engine;
      this.hello = hello;
    }

    Child.prototype.version = function() {
      return 3;
    };

    Child.prototype.upgrade = function(from) {
      Child.__super__.upgrade.call(this, from);
      return console.log('child says', this.hello);
    };

    return Child;

  })(Object);

  target = typeof exports !== "undefined" && exports !== null ? exports : window;

  target.Object = Object;

  target.Child = Child;

}).call(this);
