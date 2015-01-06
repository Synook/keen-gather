express = require 'express'
app = express()
http = require('http').Server app
io = require('socket.io') http

MAX_AGE = 60 # seconds

app.use express.static(__dirname + '/public')

# TODO: some sort of timeout so users are removed eventually
# user: {id, name, room, coords, time}
class Users
  constructor: () -> @users = {}

  update: (data) -> (@users[data.room] ||= {})[data.id] = data

  room: (room) ->
    if @users[room]
      users = {}
      for id, user of @users[room]
        user.age = Math.round((Date.now() - user.time) / 1000)
        if user.age > MAX_AGE
          delete @users[room][id]
        else
          users[id] = user
      users
    else
      {}

users = new Users()

io.on 'connection', (socket) ->
  room = null
  socket.on 'locate', (data) ->
    data.time = Date.now()
    data.age = 0
    data.name = '???' unless data.name
    console.log data
    socket.join(room = data.room) unless room
    users.update data
    io.to(room).emit 'located', data
  socket.on 'list', ->
    console.log room
    socket.emit 'listed', users.room(room)

port = process.env.PORT || 5000
http.listen port
console.log "Listening on port #{port}."