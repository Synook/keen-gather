MAX_AGE = 60 * 10 # seconds
VERSION = 2
DEFAULT_NAME = '???'

class User

  constructor: (room, @map, @socket, @render) ->
    @have_listed = false
    @name = localStorage.name || DEFAULT_NAME
    @set_room room

    @users = {}
    @timeouts = {}
    @socket.on 'located', (data) => @located data
    @socket.on 'listed', (data) => @listed data

  id: () ->
    if (
      !localStorage.id || !localStorage.version ||
      parseInt(localStorage.version) < VERSION
    )
      localStorage.id = Math.random().toString()[2..]
      localStorage.version = VERSION
    else
      localStorage.id

  set_name: (@name) ->
    localStorage.name = @name
    @locate()

  set_room: (@room) ->
    url = window.location.origin + window.location.pathname + '#' + @room
    $('a.url').attr('href', url).html url
    $('strong.code').html @room
    $('#map-code').html if @room then "##{@room}" else ''
    @locate()

  locate: (coords) ->
    return if @room is null
    if coords then @coords = coords else coords = @coords
    return if !coords

    user = 
      id: @id()
      name: @name
      room: @room
      coords: coords
      age: 0
      #time: Date.now()

    @socket.emit 'locate', user
    @located user
    if !@have_listed
      @list()
      @have_listed = true
      

  list: -> @socket.emit 'list'

  identify: (name) -> @name = name

  located: (user, defer) ->

    if @users[user.id]
      user.marker = @users[user.id].marker
      user.marker.update user.coords
      clearTimeout @timeouts[user.id]
      $(".user-marker-#{user.id}").html user.name
    else
      user.marker = @new_marker user

    opacity = (MAX_AGE - user.age) / MAX_AGE
    opacity = 1 if opacity > 1
    opacity = 0 if opacity < 0
    fade = =>
      if (opacity -= 0.1) > 0.1
        user.marker.setOpacity opacity
      else
        @map.removeLayer user.marker
        delete @users[user.id]
        clearInterval @timeouts[user.id]
        @render @users

    user.marker.setOpacity opacity
    clearInterval @timeouts[user.id]
    @timeouts[user.id] = setInterval fade, MAX_AGE / 10 * 1000

    @users[user.id] = user
    @render @users unless defer

  listed: (users) ->
    console.log users
    for id, user of users
      @located user, true
    @render @users

  new_marker: (user) ->
    marker = L.marker user.coords, icon: @icon(user)
    marker.addTo @map
    marker

  icon: (user) ->
    L.divIcon
      className: "user-marker user-marker-#{user.id}"
      html: user.name || DEFAULT_NAME
      iconSize: null

module.exports = User