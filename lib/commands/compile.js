var roots = require('../index'),
    path = require('path'),
    shell = require('shelljs');

var _compile = function(args, done, errback){
  shell.rm('-rf', roots.project.path('public'));

  if (args.compress == false) roots.project.compress = false;

  roots.compile_project(roots.project.rootDir, done, errback);

  if (roots.project.conf('compress')) {
    roots.print.log('\nminifying & compressing...\n', 'grey');
  }
};

module.exports = { execute: _compile, needs_config: true };
