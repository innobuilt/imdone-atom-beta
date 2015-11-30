engine = require 'engine.io'
minimatch = require 'minimatch'

# DONE:30 implement socket server to handle opening files in configured client issue:48
module.exports =
  clients: {}
  init: (port) ->
    return @ if @isListening
    # DOING:0 Check if something else is listening on port issue:51
    http = require('http').createServer()
    http.on 'error', (err) =>
      # TODO:0 if something is listening we should connect as a client and use the server as a proxy
      console.log err
    http.listen port, =>
      @server = engine.attach(http);
      @server.on 'connection', (socket) =>
        socket.send JSON.stringify(imdone: 'ready')
        socket.on 'message', (msg) =>
          @onMessage socket, msg
        socket.on 'close', () =>
          editor = (key for key, value of @clients when value == socket)
          delete @clients[editor] if editor
      @isListening = true
    @

  onMessage: (socket, json) ->
    try
      msg = JSON.parse json
      if (msg.hello)
        @clients[msg.hello] = socket
      console.log 'message received:', msg
    catch error
      console.log 'Error receiving message:', json

  openFile: (project, path, line, cb) ->
    editor = @getEditor path
    # DONE:10 only send open request to editors who deserve them issue:48
    socket = @getSocket editor
    return cb(false) unless socket
    socket.send JSON.stringify({project, path, line}), () ->
      cb(true)

  getEditor: (path) ->
    openIn = atom.config.get('imdone-atom.openIn')
    for editor, pattern of openIn
      if pattern
        return editor if minimatch(path, pattern, {matchBase: true})
    "atom"

  getSocket: (editor) ->
    socket = @clients[editor]
    return null unless socket && @server.clients[socket.id] == socket
    socket
