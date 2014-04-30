path        = require 'path'
W           = require 'when'
http        = require 'http'
connect     = require 'connect'
infestor    = require 'infestor'
util        = require 'util'
WebSocket   = require 'faye-websocket'
superstatic = require 'superstatic'

###*
 * @class Server
 * @classdesc Serves up a roots project locally, handles live reloading
 * @todo investigate superstatic
###

class Server

  ###*
   * Creates a new instance of the server
   *
   * @param  {Function} roots - roots class instance
   * @param  {String} dir - directory to serve
  ###

  constructor: (@roots, @dir) ->

  ###*
   * Stores all the sockets being used for pushing reloads
   * @type {Array}
  ###
  sockets: []

  ###*
   * Start the local server on the given port.
   *
   * @param  {Integer} port - number of port to start the server on
   * @return {Promise} promise for the server object
  ###

  start: (port) ->
    def = W.defer()
    @server = superstatic.createServer
      port: port
      cwd: @roots.config.output_path()
      config: @roots.config.server

    # if @roots.config.env == 'development' then initialize_websockets.call(@)
    if @roots.config.env == 'development' then inject_dev_js.call(@, @server)

    @server.start => def.resolve()
    def.promise.yield(@server)

  ###*
   * Close the server and remove it.
  ###

  close: ->
    @server.stop()
    delete @server

  ###*
   * Send a message through websockets to the browser.
   *
   * @param  {String} k - message key
   * @param  {???} v - message value
  ###

  send_msg: (k, v) ->
    sock.send(JSON.stringify(type: k, data: v)) for sock in @sockets

  ###*
   * These three methods send 'reload', 'compiling', and 'error' messages
   * through to the browser.
  ###

  reload: -> @send_msg('reload')
  compiling: -> @send_msg('compiling')
  show_error: (err) -> @send_msg('error', err)

  # @api private

  ###*
   * Given a connect app, adds middleware which injects a snippet to add
   * roots' development js, which connectes up to the socket and handles browser
   * reload and compiling events.
   *
   * @param  {Function} app - connect app instance
  ###

  inject_dev_js = (server) ->
    server.use(infestor content:
      "<!-- roots development configuration -->
      <script>var __livereload = #{@roots.config.live_reload};</script>
      <script src='__roots__/main.js'></script>"
    )
    server.use('/__roots__', connect.static(path.resolve(__dirname, 'browser')))

  ###*
   * Initializes websockets on the server instance.
  ###

  initialize_websockets = ->
    @server.on 'upgrade', (req, socket, body) =>
      if WebSocket.isWebSocket(req)
        ws = new WebSocket(req, socket, body)
        ws.on('open', => @sockets.push(ws))

module.exports = Server
