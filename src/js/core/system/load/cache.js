define([
  "core/schema/tools/dumpjson",
  "digest/sha1"
],
function(Dumpjson, Sha1) {
  var Cache ;

  Cache = {
    save_cache: function(name, model, out) {
      if (model === undefined) model = Load.load(name);
      if (out === undefined) out = find_json(name);
      res = Cache.add_metadata(name, model);
      res._set("model", ToJSON.to_json(model, true));
      return File.open(function(f) {
        return f.write(JSON.pretty_generate(res, new EnsoHash ( { allow_nan: true, max_nesting: false } )));
      }, out, "w+");
    },

    load_cache: function(name, input) {
      if (input === undefined) input = find_json(name);
      type = name.split(".")._get(- 1);
      factory = Factory.new(Load.load(S(type, ".schema")));
      json = System.readJSON(input);
      res = ToJSON.from_json(factory, json._get("model"));
      res.factory().file_path()._set(0, json._get("source"));
      json._get("depends").each(function(dep) {
        return res.factory().file_path().push(dep._get("filename"));
      });
      return res;
    },

    check_dep: function(name) {
      try {
        path = Cache.find_json(name);
        json = System.readJSON(path);
        return Cache.check_file(json) && json._get("depends").all_P(function(e) {
          return Cache.check_file(e);
        });
      } catch ( e ) {
        return false;
      }
    },

    clean: function(name) {
      if (name === undefined) name = null;
      if (name == null) {
        if (File.exists_P(S(Cache.cache_path(), "*"))) {
          return File.delete(S(Cache.cache_path(), "*"));
        }
      } else if (File.exists_P(Cache.find_json(name))) {
        return File.delete(Cache.find_json(name));
      }
    },

    cache_path: function() {
      return "core/system/load/cache/";
    },

    find_json: function(name) {
      if (["schema.schema", "schema.grammar", "grammar.schema", "grammar.grammar"].include_P(name)) {
        return S("core/system/boot/", name.gsub(".", "_"), ".json");
      } else {
        return S(Cache.cache_path(), name.gsub(".", "_"), ".json");
      }
    },

    check_file: function(element) {
      path = element._get("source");
      checksum = element._get("checksum");
      try {
        return Cache.readHash(path) == checksum;
      } catch ( DUMMY ) {
        return false;
      }
    },

    get_meta: function(name) {
      e = new EnsoHash ( { } );
      Load.Loader.find_model(function(path) {
        e._set("source", path);
        e._set("date", File.ctime(path));
        return e._set("checksum", Cache.readHash(path));
      }, name);
      return e;
    },

    add_metadata: function(name, model) {
      if (name == null) {
        e = new EnsoHash ( { } );
      } else {
        e = Cache.get_meta(name);
        type = name.split(".")._get(- 1);
        deps = [];
        deps.push(Cache.get_meta(S(type, ".schema")));
        deps.push(Cache.get_meta(S(type, ".grammar")));
        model.factory().file_path()._get(Range.new(1, - 1)).each(function(fn) {
          return deps.push(Cache.get_meta(fn.split("/")._get(- 1)));
        });
        e._set("depends", deps);
      }
      return e;
    },

    readHash: function(path) {
      hashfun = Digest.SHA1.new();
      fullfilename = path;
      Cache.open(function(io) {
        while (! io.eof()) {
          readBuf = io.readpartial(50);
          hashfun.update(readBuf);
        }
      }, fullfilename, "r");
      return hashfun.to_s();
    },

  };
  return Cache;
})