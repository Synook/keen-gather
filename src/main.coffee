$ ->
  MAX_AGE = 60 * 5 # seconds
  DEFAULT_NAME = '???'
  VERSION = 2

  socket = io()

  switchToList = ->
    $('#map').css display: 'none'
    $('#list-container').css display: 'block'
    $('#list-button').addClass 'active'
    $('#map-button').removeClass 'active'

  switchToMap = ->
    $('#map').css display: 'block'
    $('#list-container').css display: 'none'
    $('#list-button').removeClass 'active'
    $('#map-button').addClass 'active'

  socket.on 'connect', ->

    map = L.map('map').setView [51.505, -0.09], 13
    L.tileLayer(
      'http://{s}.tile.osm.org/{z}/{x}/{y}.png',
      attribution: '&copy; <a href="http://osm.org/copyright">OpenStreetMap</a>'
    ).addTo map

    class User

      constructor: (@render) ->
        @have_listed = false
        @name = localStorage.name
        @room = window.location.hash[1..] || 'default'
        console.log @room

        @users = {}
        @timeouts = {}
        socket.on 'located', (data) => @located data
        socket.on 'listed', (data) => @listed data

      id: () ->
        if (
          !localStorage.id || !localStorage.version ||
          parseInt(localStorage.version) < VERSION
        )
          localStorage.id = Math.random().toString()[2..]
          localStorage.version = VERSION
        else
          localStorage.id

      set_name: (name) ->
        localStorage.name = name
        @name = name
        @locate if @coords

      locate: (coords) ->
        if coords then @coords = coords else coords = @coords
        return if !coords

        user = 
          id: @id()
          name: @name
          room: @room
          coords: coords
          age: 0
          #time: Date.now()

        socket.emit 'locate', user
        @located user
        if !@have_listed
          @list()
          @have_listed = true
          

      list: -> socket.emit 'list'

      identify: (name) -> @name = name

      located: (user, defer) ->
        console.log 'located', user, defer

        #content = if user.id == @id then '<strong>YOU</strong>' else user.name

        if @users[user.id]
          user.marker = @users[user.id].marker
          user.marker.update user.coords
          clearTimeout @timeouts[user.id]
          $(".user-marker-#{user.id}").html user.name
        else
          user.marker = @new_marker user
          #user.marker.bindPopup content

        opacity = (MAX_AGE - user.age) / MAX_AGE
        console.log opacity
        opacity = 1 if opacity > 1
        opacity = 0 if opacity < 0
        fade = =>
          console.log "fading #{user.id}"
          if (opacity -= 0.1) > 0.1
            user.marker.setOpacity opacity
          else
            map.removeLayer user.marker
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
        marker.addTo map
        marker

      icon: (user) ->
        L.divIcon
          className: "user-marker user-marker-#{user.id}"
          html: user.name || DEFAULT_NAME
          iconSize: null

    make_click = (coords) ->
      return ->
        map.setView coords
        switchToMap()
    users = new User (users) ->
      $('#num-people').html Object.keys(users).length
      list = $ '#list'
      for element in list.find 'li'
        if element.id[5..] not in users
          element.remove()
      for id, user of users
        if !(element = list.find "#list-#{id}").length
          list.prepend $('<li></li>').append($("<a>#{user.name || '?'}</a>")
            .bind('click', make_click user.coords)
          )

    if navigator.geolocation
      navigator.geolocation.getCurrentPosition (position) ->
        coords = [position.coords.latitude, position.coords.longitude]
        map.setView coords
        users.locate coords

        navigator.geolocation.watchPosition (position) ->
          users.locate [position.coords.latitude, position.coords.longitude]

        i = 0
        setInterval ->
          #$('#status').html "locating #{i++}... #{socket.connected}"
          users.locate()
        , 5000

      , (err) ->
        alert('SADFACE')

    if !localStorage.name
      $('#identify').css display: 'block'
      $('#identify').bind 'submit', ->
        console.log "name: ", $('#identify-name').val()
        users.set_name $('#identify-name').val()
        $('#identify').css display: 'none'
        false

  $('#list-button').bind 'click', switchToList
  $('#map-button').bind 'click', switchToMap
