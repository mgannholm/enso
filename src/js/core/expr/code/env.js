define([
],
function() {
  var Env ;

  var BaseEnv = MakeMixin([], function() {
    this.parent = function() { return this.$.parent };
    this.set_parent = function(val) { this.$.parent  = val };

    this.set_in_place = function(block, key) {
      var self = this; 
      return self._set(key, block(self._get(key)));
    };

    this.set = function(block, key) {
      var self = this; 
      var res;
      res = self.clone();
      res.set_in_place(key, block);
      return res;
    };

    this.set_parent = function(env) {
      var self = this; 
      self.$.parent = env;
      return self;
    };

    this.set_grandparent = function(env) {
      var self = this; 
      if (self.$.parent == null || self.$.parent == new EnsoHash ({ })) {
        return self.set_parent(env);
      } else {
        return self.$.parent.set_grandparent(env);
      }
    };

    this.add = function(env) {
      var self = this; 
      self.set_parent(env);
      return self;
    };

    this.to_s = function() {
      var self = this; 
      var r;
      r = [];
      self.each(function(k, v) {
        return r.push(S(k, "=>", v));
      });
      return S("{ ", r.join(", "), " }");
    };

    this.clone = function() {
      var self = this; 
      return self;
    };
  });

  var HashEnv = MakeClass("HashEnv", null, [BaseEnv],
    function() {
    },
    function(super$) {
      this.initialize = function(hash) {
        var self = this; 
        if (hash === undefined) hash = new EnsoHash ({ });
        return self.$.hash = hash;
      };

      this._get = function(key) {
        var self = this; 
        if (self.$.hash.has_key_P(key)) {
          return self.$.hash._get(key);
        } else {
          return self.$.parent && self.$.parent._get(key);
        }
      };

      this._set = function(key, value) {
        var self = this; 
        if (self.$.parent && self.$.parent.has_key_P(key)) {
          return self.$.parent._set(key, value);
        } else {
          return self.$.hash._set(key, value);
        }
      };

      this.has_key_P = function(key) {
        var self = this; 
        return self.$.hash.has_key_P(key) || self.$.parent && self.$.parent.has_key_P(key);
      };

      this.keys = function() {
        var self = this; 
        return (self.$.hash.keys() + (self.$.parent == null
          ? []
          : self.$.parent.keys())).uniq();
      };

      this.to_s = function() {
        var self = this; 
        return self.$.hash.to_s();
      };

      this.clone = function() {
        var self = this; 
        return HashEnv.new(self.$.hash.clone()).set_parent(self.$.parent);
      };
    });

  var ObjEnv = MakeClass("ObjEnv", null, [BaseEnv],
    function() {
    },
    function(super$) {
      this.obj = function() { return this.$.obj };

      this.initialize = function(obj, parent) {
        var self = this; 
        if (parent === undefined) parent = null;
        self.$.obj = obj;
        return self.$.parent = parent;
      };

      this._get = function(key) {
        var self = this; 
        if (key == "self") {
          return self.$.obj;
        } else if (self.$.obj.schema_class().all_fields().any_P(function(f) {
          return f.name() == key;
        })) {
          return self.$.obj._get(key);
        } else {
          return self.$.parent && self.$.parent._get(key);
        }
      };

      this._set = function(key, value) {
        var self = this; 
        return self.$.obj._set(key, value);
      };

      this.has_key_P = function(key) {
        var self = this; 
        return (key == "self" || self.$.obj.schema_class().all_fields()._get(key)) || self.$.parent && self.$.parent.has_key_P(key);
      };

      this.keys = function() {
        var self = this; 
        return (self.$.obj.schema_class().all_fields().keys() + (self.$.parent == null
          ? []
          : self.$.parent.keys())).uniq();
      };

      this.to_s = function() {
        var self = this; 
        return self.$.obj.to_s();
      };

      this.type = function(fname) {
        var self = this; 
        return self.$.obj.schema_class().all_fields()._get(fname).type();
      };

      this.clone = function() {
        var self = this; 
        return ObjEnv.new(self.$.obj).set_parent(self.$.parent);
      };
    });

  var LambdaEnv = MakeClass("LambdaEnv", null, [BaseEnv],
    function() {
    },
    function(super$) {
      this.initialize = function(block, label) {
        var self = this; 
        self.$.label = label;
        return self.$.block = block;
      };

      this._get = function(key) {
        var self = this; 
        var res;
        if (self.$.label == key) {
          res = self.$.block();
          return res;
        } else {
          return self.$.parent && self.$.parent._get(key);
        }
      };

      this._set = function(key, value) {
        var self = this; 
        if (self.$.label == key) {
          return self.raise(S("Trying to modify read-only variable ", key));
        } else {
          return self.$.parent._set(key, value);
        }
      };

      this.has_key_P = function(key) {
        var self = this; 
        return self.$.label == key || self.$.parent && self.$.parent.has_key_P(key);
      };

      this.keys = function() {
        var self = this; 
        return ([self.$.label] + (self.$.parent == null
          ? []
          : self.$.parent.keys())).uniq();
      };

      this.to_s = function() {
        var self = this; 
        return self.$.block.to_s();
      };

      this.clone = function() {
        var self = this; 
        return LambdaEnv.new(self.$.label, self.$.block).set_parent(self.$.parent);
      };
    });

  Env = {
    deepclone: function(env) {
      var self = this; 
      var c;
      c = env.clone();
      if (! (env.parent() == null)) {
        return c.set_parent(Env.deepclone(env.parent()));
      } else {
        return c;
      }
    },

    BaseEnv: BaseEnv,
    HashEnv: HashEnv,
    ObjEnv: ObjEnv,
    LambdaEnv: LambdaEnv,

  };
  return Env;
})
