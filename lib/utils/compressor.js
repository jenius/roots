var transformer = require('transformers'),
    htmlmin = require('html-minifier'),
    CleanCSS = require('clean-css');

module.exports = function(content, extension){

  // TODO: This should ignore js files with ".min" in the name
  if (extension === 'js') {
    transformer['uglify-js'].renderSync(content); 
  }

  if (extension === 'css') {
    return new CleanCSS().minify(content);
  }

  if (extension === 'html') {
    htmlmin.minify(content, { removeComments: true, collapseWhitespace: true })
  } 

  return content;
};
