should = require 'should'
path = require 'path'
fs = require 'fs'
colors = require 'colors'
shell = require 'shelljs'
config = require '../lib/global_config'
run = require('child_process').exec
root = path.join __dirname
basic_root = path.join root, 'sandbox/basic'

#
# command line interface
#

# can't test watch because the process hangs - the internals of
# the watch command are tested below in the compiler section though

files_exist = (test_path, files) ->
  for file in files
    fs.existsSync(path.join(test_path, file)).should.be.ok

describe 'command', ->
  describe 'compile', -> # ----------------------------------------------------------------
    before (done) ->
      run "cd \"#{basic_root}\"; ../../../bin/roots compile", done

    it 'should compile files to /public', ->
      fs.readdirSync(path.join(basic_root, 'public')).should.have.lengthOf(5)

    it 'should minify all css and javascript', () ->
      js_content = fs.readFileSync path.join(basic_root, 'public/js/main.js'), 'utf8'
      js_content.should.not.match /\n/

    it 'should compile all files to public', ->
      css_content = fs.readFileSync path.join(basic_root, 'public/css/example.css'), 'utf8'
      css_content.should.not.match /\n/
      shell.rm '-rf', path.join(basic_root, 'public')

  describe 'new', -> # --------------------------------------------------------------------
    test_path = path.join(root, 'testproj')

    it 'should use the default template if no flags present', (done) ->
      run "cd \"#{root}\"; ../bin/roots new testproj", ->
        files_exist(test_path,[
          '/'
          'app.coffee'
          'readme.md'
          'views'
          'views/index.jade'
          'views/layout.jade'
          'assets'
          'assets/favicon.ico'
          'assets/css'
          'assets/css/_settings.styl'
          'assets/css/master.styl'
          'assets/js'
          'assets/js/main.coffee'
          'assets/js/_helper.coffee'
          'assets/js/require.js'
          'assets/img'
          'assets/img/noise.png'
        ])
        shell.rm '-rf', path.join(root, 'testproj')
        done()

    it 'should use express template if the --express flag is present', (done) ->
      run "cd \"#{root}\"; ../bin/roots new testproj --express", ->
        files_exist(test_path,[
          '/'
          'app.js'
          'routes'
          'assets'
          'views'
          'public'
        ])
        shell.rm '-rf', path.join(root, 'testproj')
        done()

    it 'should use basic template if the --basic flag is present', (done) ->
      run "cd \"#{root}\"; ../bin/roots new testproj --basic", ->
        files_exist(test_path,[
          '/'
          'views/index.html'
          'assets/js/main.js'
          'assets/css/example.css'
        ])
        shell.rm '-rf', path.join(root, 'testproj')
        done()

  describe 'plugin', -> # -----------------------------------------------------------------
    it 'should create a template inside /plugins on \'generate\'', (done) ->
      run "cd \"#{basic_root}\"; ../../../bin/roots plugin generate", ->
        fs.existsSync(path.join(basic_root, 'plugins/template.coffee')).should.be.ok
        shell.rm '-rf', path.join(basic_root, 'plugins')
        done()

    it 'should use the javascript template if called with --js', (done) ->
      run "cd \"#{basic_root}\"; ../../../bin/roots plugin generate --js", ->
        fs.existsSync(path.join(basic_root, 'plugins/template.js')).should.be.ok
        shell.rm '-rf', path.join(basic_root, 'plugins')
        done()

  describe 'version', -> # ----------------------------------------------------------------
    it 'should output the correct version number for roots', (done) ->
      version = JSON.parse(fs.readFileSync('package.json')).version
      run './bin/roots version', (err,out) ->
        out.replace(/\n/, '').should.eql(version)
        done()

  describe 'pkg', -> # ---------------------------------------------------------------------
    it 'should expose the correct package manager\'s interface', (done) ->
      pkg_mgr = config.get().package_manager
      run "cd \"#{basic_root}\"; ../../../bin/roots pkg", (err,out, stdout) ->
        out.should.match /cli-js/ if (pkg_mgr == 'cdnjs')
        out.should.match /bower/ if (pkg_mgr == 'bower')
        done()

describe 'compiler', ->
  compiler = null

  before ->
    Compiler = require path.join(root, '../lib/compiler')
    compiler = new Compiler()

  it 'eventemitter should be hooked up properly', (done) ->
    compiler.on 'finished', -> done()
    compiler.finish()

describe 'jade', ->
  jade_path = path.join root, 'sandbox/jade'
  jade_path_2 = path.join root, 'sandbox/no-layout'

  it 'should compile jade view templates', (done) ->
    run "cd \"#{jade_path}\"; ../../../bin/roots compile --no-compress", ->
      fs.existsSync(path.join(jade_path, 'public/index.html')).should.be.ok
      shell.rm '-rf', path.join(jade_path, 'public')
      done()

  it 'should compile templates with no layout', (done) ->
    run "cd #{jade_path_2}; ../../../bin/roots compile --no-compress", ->
      fs.existsSync(path.join(jade_path_2, 'public/index.html')).should.be.ok
      shell.rm '-rf', path.join(jade_path_2, 'public')
      done()

describe 'ejs', ->
  ejs_path = path.join root, 'sandbox/ejs'

  it 'should compile ejs', (done) ->
    run "cd \"#{ejs_path}\"; ../../../bin/roots compile --no-compress", ->
      fs.existsSync(path.join(ejs_path, 'public/index.html')).should.be.ok
      shell.rm '-rf', path.join(ejs_path, 'public')
      done()

describe 'coffeescript', ->
  coffeescript_path = path.join root, 'sandbox/coffeescript'
  coffeescript_path_2 = path.join root, 'sandbox/coffee-basic'

  it 'should compile coffeescript and requires should work', (done) ->
    run "cd \"#{coffeescript_path}\"; ../../../bin/roots compile --no-compress", ->
      fs.existsSync(path.join(coffeescript_path, 'public/basic.js')).should.be.ok
      fs.existsSync(path.join(coffeescript_path, 'public/require.js')).should.be.ok
      require_content = fs.readFileSync path.join(coffeescript_path, 'public/require.js'), 'utf8'
      require_content.should.match /BASIC/
      shell.rm '-rf', path.join(coffeescript_path, 'public')
      done()

  it 'should compile without closures when specified in app.coffee', (done) ->
    run "cd \"#{coffeescript_path_2}\"; ../../../bin/roots compile --no-compress", ->
      fs.existsSync(path.join(coffeescript_path_2, 'public/testz.js')).should.be.ok
      require_content = fs.readFileSync path.join(coffeescript_path_2, 'public/testz.js'), 'utf8'
      require_content.should.not.match /function/
      shell.rm '-rf', path.join(coffeescript_path_2, 'public')
      done()

describe 'stylus', ->
  stylus_path = path.join root, 'sandbox/stylus'

  before (done) ->
    run "cd \"#{stylus_path}\"; ../../../bin/roots compile --no-compress", ->
      done()

  it 'should compile stylus with roots css', ->
    fs.existsSync(path.join(stylus_path, 'public/basic.css')).should.be.ok

  it 'should include the project directory for requires', ->
    fs.existsSync(path.join(stylus_path, 'public/req.css')).should.be.ok
    fs.existsSync(path.join(stylus_path, 'public/nested/all.css')).should.be.ok
    require_content = fs.readFileSync path.join(stylus_path, 'public/req.css'), 'utf8'
    require_content.should.match /#000/
    shell.rm '-rf', path.join(stylus_path, 'public')

describe 'static files', ->
  static_path = path.join root, 'sandbox/static'

  before (done) ->
    run "cd \"#{static_path}\"; ../../../bin/roots compile --no-compress", ->
      done()

  it 'copies static files', ->
    fs.existsSync(path.join(static_path, 'public/whatever.poop')).should.be.ok
    require_content = fs.readFileSync path.join(static_path, 'public/whatever.poop'), 'utf8'
    require_content.should.match /roots dont care/
    shell.rm '-rf', path.join(static_path, 'public')

describe 'errors', ->
  errors_path = path.join root, 'sandbox/errors'

  it 'notifies you if theres an error', (done) ->
    run "cd \"#{errors_path}\"; ../../../bin/roots compile --no-compress", (a,b,stderr) ->
      stderr.should.match /ERROR/
      shell.rm '-rf', path.join(errors_path, 'public')
      done()

describe 'dynamic content', ->
  dynamic_path = path.join root, 'sandbox/dynamic'

  before (done) ->
    run "cd \"#{dynamic_path}\"; ../../../bin/roots compile --no-compress", ->
      done()

  it 'compiles dynamic files', ->
    fs.existsSync(path.join(dynamic_path, 'public/posts/hello_world.html')).should.be.ok
    content = fs.readFileSync path.join(dynamic_path, 'public/posts/hello_world.html'), 'utf8'
    content.should.match(/\<h1\>hello world\<\/h1\>/)
    content.should.match(/This is my first blog post/)
    shell.rm '-rf', path.join(dynamic_path, 'public')

describe 'precompiled templates', ->
  precompile_path = path.join root, 'sandbox/precompile'

  before (done) ->
    run "cd #{precompile_path}; ../../../bin/roots compile --no-compress", ->
      done()

  it 'precompiles templates', ->
    fs.existsSync(path.join(precompile_path, 'public/js/templates.js')).should.be.ok
    require_content = fs.readFileSync path.join(precompile_path, 'public/js/templates.js'), 'utf8'
    require_content.should.match(/\<p\>hello world\<\/p\>/)
    shell.rm '-rf', path.join(precompile_path, 'public')

describe 'multipass compiles', ->
  multipass_path = path.join root, 'sandbox/multipass'

  before (done) ->
    run "cd #{multipass_path}; ../../../bin/roots compile --no-compress", ->
      done()

  it 'will compile a single file multiple times accurately', ->
    fs.existsSync(path.join(multipass_path, 'public/index.html')).should.be.ok
    content = fs.readFileSync path.join(multipass_path, 'public/index.html'), 'utf8'
    content.should.match(/blarg world/)
    shell.rm '-rf', path.join(multipass_path, 'public')

describe 'deploy', ->
  deployer = null

  before ->
    Deployer = require path.join(root, '../lib/deployer')
    test_adapter = { test: (input)-> return input }
    deployer = new Deployer(test_adapter, '')
    deployer.add_shell_method('test');

  it 'handles adapters correctly', ->
    deployer.test(true).should.be.ok
    deployer.test(false).should.not.be.ok

  it 'has all the required shell methods', ->
    deployer.check_install_status.should.exist
    deployer.check_credentials.should.exist
    deployer.compile_project.should.exist
    deployer.add_config_files.should.exist
    deployer.commit_files.should.exist
    deployer.create_project.should.exist
    deployer.push_code.should.exist
