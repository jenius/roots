var run = require('child_process').exec,
    colors = require('colors');


var _update = function(){

  // there should be some sort of check for updates as well

  console.log("updating...".yellow);

  run('npm install roots -g', function(err, out, stderr){
    if (err) {
      console.log("something went seriously wrong here.\nfile an issue on http://github.com/jenius/roots/issues".red);
    } else {
      console.log("done!".green);
    }
  });

};

module.exports = { execute: _update };
