$(document).ready ->

  nav_toggler = $("header .toggle-nav")
  nav = $("#main-nav")
  content = $("#content")
  body = $("body")
  # if you are customizing main navigation width, you need to customize nav_closed_width variable too
  nav_closed_width = 50
  nav_open = body.hasClass("main-nav-opened") || nav.width() > nav_closed_width

  $("#main-nav .dropdown-collapse").on "click", (e) ->
    e.preventDefault()
    link = $(this)
    list = link.parent().find("> ul")

    if list.is(":visible")
      if body.hasClass("main-nav-closed") && link.parents("li").length == 1
        false
      else
        link.removeClass("in")
        list.slideUp 300, ->
          $(this).removeClass("in")
    else
      link.addClass("in")
      list.slideDown 300, ->
        $(this).addClass("in")
    false

  nav.swiperight (event, touch) ->
    $(document).trigger("nav-open")
  nav.swipeleft (event, touch) ->
    $(document).trigger("nav-close")

  nav_toggler.on "click", ->
    if nav_open
      $(document).trigger("nav-close")
    else
      $(document).trigger("nav-open")
    false

  # callbacks
  $(document).bind "nav-close", (event, params) ->
    body.removeClass("main-nav-opened").addClass("main-nav-closed")
    nav_open = false

  $(document).bind "nav-open", (event, params) ->
    body.addClass("main-nav-opened").removeClass("main-nav-closed")
    nav_open = true