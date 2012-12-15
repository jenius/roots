var stylus = require('stylus'),
    roots_css = require('roots-css');

exports.settings = { file_type: 'styl', target: 'css' }

exports.compile = function(files, Helper, cb){
  var error;
  files.forEach(function(file){

    var helper = new Helper(file)

    stylus(helper.file_contents)
      // for more accurate error reporting
      .set('filename', file)
      // for compression
      .set('compress', global.options.compress)
      // for imports to work
      .include(require('path').dirname(helper.file_path))
      // load roots css library
      .use(roots_css())
      // do work son
      .render(function(err, compiled_css){ // do work
        if (err) { error = err }
        helper.write( compiled_css )
      });
  });
  cb(error);
}