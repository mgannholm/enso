var requirejs = require('requirejs');

requirejs.config({
   nodeRequire: require,
   baseUrl: 'js',
});

requirejs(["enso", "./core/system/boot/meta_schema"],
function(Enso, Boot) {

   x = Boot.load_path("/Users/wcook/enso/src/core/system/boot/schema_schema.json");
  console.log("x._id = " + x._id()) ;
  console.log("Test = " + x.toString());
  console.log("Test = " + x.types().to_s());
  console.log("Test = " + x.types()._get("Primitive").name()) ;
  console.log("Test = " + x.types()._get("Primitive").to_s()) ;
  console.log("Test = " + x.types()._get("Class").all_fields()) ;
  console.log("Test = " + x.types()._get("Class").defined_fields()) ;
  console.log("Test = " + x.types()._get("Class").supers()) ;

})