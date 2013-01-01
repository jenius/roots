var colors            = require('colors'),
    debug             = require('./debug'),
    path              = require('path'),
    currentDirectory  = path.normalize(process.cwd()),
    utils             = require('./utils');

// -----------------------
// compile all the things!
// -----------------------

exports.compile_project = function(cb){

  // -------------------------------------------------------------------
  // Async Management
  // -------------------------------------------------------------------

  // Since the compiling process is completely async, this guy keeps track
  // of what has been compiled and what has not, as well as when an error
  // comes up in any of the comple processes. It adds errors as flash
  // messages if they are present, and hits the callback when all the files
  // are done compiling.

  // This really needs a refactor, but is super tough because of the async
  // nature of everything and the density of logic in here. Will happen in
  // phase 3 refactoring, hopefully.

  var reload = 0;
  var error = false;

  var next = function(counter, compile_error){
    var lang = counter.shift();

    if (compile_error) { error = compile_error }

    if (counter.length < 1 ) {
      reload++;
      if (cb !== undefined && reload > 3) {
        if (error) {
          utils.add_error_messages(error, function(){ debug.log('reloading page'.red); cb(); });
        } else {
          process.stdout.write('done!\n'.green); cb();
        }
      }
    }

  };

  process.stdout.write('compiling project... '.grey);
  debug.log("");

  // -------------------------------------------------------------------
  // view and asset compilation
  // -------------------------------------------------------------------

  var views = {
    file_types:   global.options.file_types.html,
    ignore_files: global.options.ignore_files,
    folder:       global.options.folder_config.views
  };

  var assets = {
    file_types:   global.options.file_types.css.concat(global.options.file_types.js),
    ignore_files: global.options.ignore_files,
    folder:       global.options.folder_config.assets
  };

  var compile = function(config_object){
    utils.create_structure(config_object, function(compiled_files, static_files){
      utils.compile_files(config_object.file_types, compiled_files, next);
      utils.copy_static_files(config_object.folder, static_files, next);
    });
  }

  compile(views);
  compile(assets);

  // -------------------------------------------------------------------
  // image compilation
  // -------------------------------------------------------------------

  var imgSource = path.join(currentDirectory, global.options.folder_config.assets, 'img');
  var imgDestination = path.join(currentDirectory, 'public/img');

  utils.process_images(imgSource, imgDestination)

};