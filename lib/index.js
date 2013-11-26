require('coffee-script');

var colors = require('colors'),
    path = require('path'),
    async = require('async'),
    shell = require('shelljs'),
    fs = require('fs'),
    _ = require('underscore'),
    readdirp = require('readdirp'),
    minimatch = require('minimatch'),
    W = require('when'),
    fn = require('when/function');

var Project = require('./project');
var project = exports.project = new Project(process.cwd());

var yaml_parser = require('./utils/yaml_parser'),
    precompile_templates = require('./precompiler'),
    Compiler = require('./compiler'),
    printers = exports.printers = require('./print');

// initialization and error handling
var print = exports.print = new printers.Print();
terminalPrinter = new printers.TerminalPrinter(); // @private
var compiler = exports.compiler = new Compiler();

_.bindAll(compiler, 'compile', 'copy', 'finish');

compiler.on('error', function(err){
  print.error(err);
  compiler.finish();
});

// @api public
// Given a root (folder or file), compile with roots and output to /public

exports.compile_project = function(root, done, errback){

  compiler.once('finished', done);

  if (typeof errback !=='undefined') {
    compiler.on('error', errback);
  }

  fn.call(analyze, root)
  .then(function(ast){ return fn.lift(create_folders, ast)() })
  .then(compile)
  .then(precompile_templates)
  .otherwise(function(err){ compiler.emit('error', err); })
  .then(compiler.finish);
};

// @api private
// parse file/directory input and generate mini roots-style AST.

function analyze(root){
  print.debug('analyzing project', 'yellow');

  var ast = {
    folders: {},
    compiled_files: [],
    static_files: [],
    dynamic_files: []
  };

  if (fs.statSync(root).isDirectory()) {
    return parse_directory(root)
  }

  parse_file(root);
  return ast

  function parse_directory(root){
    var deferred = W.defer();

    // clear the dynamic locals first
    project.locals.site = null;

    // read through the current project and organize the files
    var options = {
      root: root,
      directoryFilter: project.ignore_folders,
      fileFilter: project.ignore_files
    };

    readdirp(options, function(err, res){
      if (err) print.error(err);

      // populate folders
      ast.folders = _.pluck(res.directories, 'fullPath');

      // populate compiled and copied files
      res.files.forEach(function(file){
        parse_file(file.fullPath);
      });

      deferred.resolve(ast);

    });

    return deferred.promise;
  }

  function parse_file(file){
    if (yaml_parser.detect(file)) {
      ast.dynamic_files.push(file);
    } else if (is_template(file)) {
      return false;
    } else if (is_compiled(file)) {
      ast.compiled_files.push(file);
    } else {
      ast.static_files.push(file);
    }
  }

  function is_compiled(file){
    return project.extensions.indexOf(path.extname(file).slice(1)) >= 0;
  }

  function is_template(file){
    return minimatch(file, '**/' + project.templates + '/*');
  }

}

// @api private
// create the folder structure for the project

function create_folders(ast){
  print.debug('creating folders', 'yellow');
  shell.mkdir('-p', project.path('public'));
  var output_path = require('./utils/output_path');

  for (var key in ast.folders) {
    shell.mkdir('-p', output_path(ast.folders[key]));
    print.debug('created ' + ast.folders[key].replace(project.rootDir,''));
  }

  return ast;
}

// @api private
// compile and write the files given a roots AST.

function compile(ast){
  var deferred = W.defer();

  print.debug('compiling and copying files', 'yellow');

  // compile dynamic content first, if present
  async.map(ast.dynamic_files, compiler.compile, function(err){
    async.parallel([compile_files, copy_static_files], function(){
      deferred.resolve(ast);
    });
  });

  function compile_files(cb){ async.map(ast.compiled_files, compiler.compile, cb); }
  function copy_static_files(cb){ async.map(ast.static_files, compiler.copy, cb); }

  return deferred.promise;
}
