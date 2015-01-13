User = require './user.coffee'

$ ->
  location_timeout = null
  socket = io()

  randomLetter = ->
    code = Math.round Math.random() * (26 * 2 - 1)
    if code < 26 then code += 65 else code += 97 - 26
    String.fromCharCode code

  switchTo = (id) ->
    $('nav a').removeClass 'active'
    $("nav a[href='#{id}']").addClass 'active'
    $('#main > div').css display: 'none'
    $(id).css display: 'block'

  $('nav a').bind 'click', ->
    switchTo $(this).attr('href')
    return false

  displayModal = (section) ->
    $('.leaflet-control-zoom').css display: 'none'
    $('#entry div div').css display: 'none'
    $('#entry').css display: 'block'
    $("##{section}").css display: 'block'

  hideModal = ->
    $('.leaflet-control-zoom').css display: 'block'
    $('#entry, #entry div div').css display: 'none'

  map = L.map('map').setView [51.505, -0.09], 13
  L.tileLayer(
    'http://{s}.tile.osm.org/{z}/{x}/{y}.png',
    attribution: '&copy; <a href="http://osm.org/copyright">OpenStreetMap</a>'
  ).addTo map

  if !navigator.geolocation
    displayModal 'location-unable'
  else
    socket.on 'connect', ->

      make_click = (coords) ->
        return ->
          map.setView coords
          switchTo '#map'
      users = new User window.location.hash[1..], map, socket, (users) ->
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

      navigator.geolocation.getCurrentPosition (position) ->
        coords = [position.coords.latitude, position.coords.longitude]
        map.setView coords
        users.locate coords

        navigator.geolocation.watchPosition (position) ->
          users.locate [position.coords.latitude, position.coords.longitude]

        setInterval ->
          users.locate()
        , 5000

      , (err) -> displayModal 'location-error'

      check_name = ->
        if !localStorage.name
          displayModal 'no-identity'
          $('#identify').bind 'submit', ->
            users.set_name $('#identify-name').val()
            hideModal()
            false

      if !window.location.hash[1..]
        displayModal 'no-hash'
        $('#map-code-input').bind 'keyup', ->
          str = (if $(this).val() then 'Use' else 'New') + ' map code'
          $('#create-code').html str
        proceed = ->
          if code = $('#map-code-input').val()
            hideModal()
          else
            code = (randomLetter() for i in [1..4]).join ''
            displayModal 'new-hash'
            url = "#{window.location.href}##{code}"
            $('#new-hash .url').attr('href', url).html url
            $('#new-hash .code').html code
            $('#new-hash button').on 'click', -> hideModal()
          console.log code
          window.location.hash = code
          users.set_room code
          $('#map-code').html window.location.hash
          check_name()
        $('#existing-map-code').bind 'submit', ->
          proceed()
          return false
        $('#create-code').bind 'click', proceed
      else check_name()
