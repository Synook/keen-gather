express = require 'express'
app = express()
http = require('http').Server app
io = require('socket.io') http

MAX_AGE = 60 * 5 # seconds

app.use express.static(__dirname + '/public')

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
    unless room == data.room
      socket.leave room unless room is null
      socket.join(room = data.room) 
    users.update data
    io.to(room).emit 'located', data
  socket.on 'list', ->
    socket.emit 'listed', users.room(room)

port = process.env.PORT || 5000
http.listen port
console.log "Listening on port #{port}."