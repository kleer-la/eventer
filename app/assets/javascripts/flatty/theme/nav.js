$(document).ready(function() {
  var nav_toggler = $("header .toggle-nav");
  var nav = $("#main-nav");
  var content = $("#content");
  var body = $("body");
  // if you are customizing main navigation width, you need to customize nav_closed_width variable too
  var nav_closed_width = 50;
  var nav_open = body.hasClass("main-nav-opened") || nav.width() > nav_closed_width;

  $("#main-nav .dropdown-collapse").on("click", function(e) {
    e.preventDefault();
    var link = $(this);
    var list = link.parent().find("> ul");

    if (list.is(":visible")) {
      if (body.hasClass("main-nav-closed") && link.parents("li").length === 1) {
        return false;
      } else {
        link.removeClass("in");
        list.slideUp(300, function() {
          $(this).removeClass("in");
        });
      }
    } else {
      link.addClass("in");
      list.slideDown(300, function() {
        $(this).addClass("in");
      });
    }
    return false;
  });

  nav.swiperight(function(event, touch) {
    $(document).trigger("nav-open");
  });
  nav.swipeleft(function(event, touch) {
    $(document).trigger("nav-close");
  });

  nav_toggler.on("click", function() {
    if (nav_open) {
      $(document).trigger("nav-close");
    } else {
      $(document).trigger("nav-open");
    }
    return false;
  });

  // callbacks
  $(document).bind("nav-close", function(event, params) {
    body.removeClass("main-nav-opened").addClass("main-nav-closed");
    nav_open = false;
  });

  $(document).bind("nav-open", function(event, params) {
    body.addClass("main-nav-opened").removeClass("main-nav-closed");
    nav_open = true;
  });
});
