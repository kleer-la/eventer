$(document).ready ->
  setTimeAgoExample()

  # --------------------------------------------------------------------------------------------------------------------
  # address book
  $('#slider').sliderNav()
  # --------------------------------------------------------------------------------------------------------------------

  # --------------------------------------------------------------------------------------------------------------------
  # adding event to calendar
  $("#new-event").live 'submit', (e) ->
    e.preventDefault()
    value = $("#new-event-input").val()

    if value.length > 0
      $("#events .box-content").prepend(("<div class='label label-important external-event'>#{value}</div>"))
      $("#new-event-input").val("")
      setDraggableEvents()
  # --------------------------------------------------------------------------------------------------------------------

  # --------------------------------------------------------------------------------------------------------------------
  # file trees
  $("#tree1").dynatree()
  $("#tree2").dynatree
    checkbox: true
    selectMode: 2
    onSelect: (select, node) ->
      selNodes = node.tree.getSelectedNodes()
      selKeys = $.map(selNodes, (node) ->
        "[" + node.data.key + "]: '" + node.data.title + "'"
      )
      $("#echoSelection2").text selKeys.join(", ")

    onClick: (node, event) ->
      node.toggleSelect()  if node.getEventTargetType(event) is "title"

    onKeydown: (node, event) ->
      if event.which is 32
        node.toggleSelect()
        false
    idPrefix: "dynatree-Cb2-"
  $("#tree3").dynatree
    dnd:
      preventVoidMoves: true
      onDragStart: (node) ->
        true
      onDragEnter: (node, sourceNode) ->
        ["before", "after"]
      onDrop: (node, sourceNode, hitMode, ui, draggable) ->
        sourceNode.move node, hitMode
  # --------------------------------------------------------------------------------------------------------------------

  # --------------------------------------------------------------------------------------------------------------------
  # jquery ui sliders
  $("#slider-example > span").each ->
    value = parseInt($(this).text(), 10)
    $(this).empty().slider
      value: value
      range: "min"
      animate: true
      orientation: "vertical"

  $("#slider-example1").slider
    value: 100
    min: 0
    max: 500
    step: 50
    slide: (event, ui) ->
      $("#slider-example1-amount").text "$" + ui.value

  $("#slider-example1-amount").text "$" + $("#slider-example1").slider("value")

  $("#slider-example2").slider
    range: true
    min: 0
    max: 500
    values: [75, 300]
    slide: (event, ui) ->
      $("#slider-example2-amount").text "$" + ui.values[0] + " - $" + ui.values[1]

  $("#slider-example2-amount").text "$" + $("#slider-example2").slider("values", 0) + " - $" + $("#slider-example2").slider("values", 1)
  # --------------------------------------------------------------------------------------------------------------------

  # --------------------------------------------------------------------------------------------------------------------
  # bootbox override classic alert
  $("#alert-example").click ->
    bootbox.dialog "This is alert!", [
      label: "Okay"
      class: "btn-danger"
    ]
  # --------------------------------------------------------------------------------------------------------------------

  # --------------------------------------------------------------------------------------------------------------------
  # growl like notifications
  $("#notification1").click ->
    $.jGrowl("Lorem ipsum dolor sit amet...");

  $("#notification2").click ->
    $.jGrowl("Lorem ipsum dolor sit amet...", {sticky: true});
  # --------------------------------------------------------------------------------------------------------------------

  # --------------------------------------------------------------------------------------------------------------------
  # select2 with icons formatter
  select2icon = (e) ->
    "<i class='" + e.text + "'></i> ." + e.text

  $("#select2-icon").select2
    formatResult: select2icon
    formatSelection: select2icon
    escapeMarkup: (e) ->
      e
  # --------------------------------------------------------------------------------------------------------------------

  # --------------------------------------------------------------------------------------------------------------------
  # select2 tags exaple
  $("#select2-tags").select2
    tags: ["today", "tomorrow", "toyota"]
    tokenSeparators: [",", " "]
    placeholder: "Type your tag here... "
  # --------------------------------------------------------------------------------------------------------------------

  # --------------------------------------------------------------------------------------------------------------------
  # custom validators
  $.validator.addMethod "buga", ((value) ->
    value is "buga"
  ), "Please enter \"buga\"!"

  $.validator.methods.equal = (value, element, param) ->
    value is param
  # --------------------------------------------------------------------------------------------------------------------

  # --------------------------------------------------------------------------------------------------------------------
  # simulating todo list
  $(".todo-list .new-todo").live 'submit', (e) ->
    todo_name = $(this).find("#todo_name").val()
    $(this).find("#todo_name").val("")
    unless todo_name.length == 0
      li = $(this).parents(".todo-list").find("li.item").first().clone()
      li.removeClass("important").removeClass("done")
      li.find("label .todo").text(todo_name)

      $(".todo-list ul").first().prepend(li)
      li.effect("highlight", {}, 500);
    e.preventDefault()
  # --------------------------------------------------------------------------------------------------------------------

  # --------------------------------------------------------------------------------------------------------------------
  # loading more content in recent activity
  $("#comments-more-activity").click (e) ->
    $(this).button("loading")
    setTimeout (->
      list = $("#comments-more-activity").parent().parent().find("ul")
      list.append(list.find("li:not(:first)").clone().effect("highlight", {}, 500))
      $("#comments-more-activity").button("reset")
    ), 1000
    e.preventDefault()

  $("#users-more-activity").click (e) ->
    $(this).button("loading")
    setTimeout (->
      list = $("#users-more-activity").parent().parent().find("ul")
      list.append(list.find("li:not(:first)").clone().effect("highlight", {}, 500))
      $("#users-more-activity").button("reset")
    ), 1000
    e.preventDefault()
  # --------------------------------------------------------------------------------------------------------------------

  # --------------------------------------------------------------------------------------------------------------------
  # simulating recent activity
  $(".todo-list .remove").live 'click', (e) ->
    $(this).tooltip("hide")
    $(this).parents("li").fadeOut 500, ->
      $(this).remove()
    e.preventDefault()

  $(".todo-list li .important").live 'click', (e) ->
    $(this).parents("li").toggleClass("important")
    e.preventDefault()

  $(".todo-list .check").live 'click', ->
    checkbox = $(this).find("input[type='checkbox']")

    if checkbox.is(":checked")
      $(this).parents("li").addClass("done")
    else
      $(this).parents("li").removeClass("done")
  # --------------------------------------------------------------------------------------------------------------------


  # --------------------------------------------------------------------------------------------------------------------
  # simulating recent activity
  $(".recent-activity .ok").live 'click', (e) ->
    $(this).tooltip("hide")
    $(this).parents("li").fadeOut 500, ->
      $(this).remove()
    e.preventDefault()

  $(".recent-activity .remove").live 'click', (e) ->
    $(this).tooltip("hide")
    $(this).parents("li").fadeOut 500, ->
      $(this).remove()
    e.preventDefault()
  # --------------------------------------------------------------------------------------------------------------------

  # --------------------------------------------------------------------------------------------------------------------
  # simulating chat
  $(".chat .new-message").live 'submit', (e) ->
    date = new Date()
    months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
    chat = $(this).parents(".chat")

    message = $(this).find("#message_body").val()
    $(this).find("#message_body").val("")

    unless message.length == 0
      li = chat.find("li.message").first().clone()
      li.find(".body").text(message)

      timeago = li.find(".timeago")
      timeago.removeClass("in")
      timeago.attr("title", "#{date.getFullYear()}-#{date.getDate()}-#{date.getMonth()+1} #{date.getHours()}:#{date.getMinutes()}:#{date.getSeconds()} +0200")
      timeago.text("#{months[date.getMonth()]} #{date.getDate()}, #{date.getFullYear()} #{date.getHours()}:#{date.getMinutes()}")
      setTimeAgo(timeago)

      sender = li.find(".name").text().trim()

      chat.find("ul").append(li)
      scrollable = li.parents(".scrollable")
      $(scrollable).slimScroll({ scrollTo: scrollable.prop('scrollHeight') + "px" });
      li.effect("highlight", {}, 500);

      reply = scrollable.find("li").not(":contains('#{sender}')").first().clone()

      setTimeout (->
        date = new Date()
        timeago = reply.find(".timeago")
        timeago.attr("title", "#{date.getFullYear()}-#{date.getDate()}-#{date.getMonth()+1} #{date.getHours()}:#{date.getMinutes()}:#{date.getSeconds()} +0200")
        timeago.text("#{months[date.getMonth()]} #{date.getDate()}, #{date.getFullYear()} #{date.getHours()}:#{date.getMinutes()}")
        setTimeAgo(timeago)

        scrollable.find("ul").append(reply)
        $(scrollable).slimScroll({ scrollTo: scrollable.prop('scrollHeight') + "px" });
        reply.effect("highlight", {}, 500);
      ), 1000

    e.preventDefault()
  # --------------------------------------------------------------------------------------------------------------------


  # --------------------------------------------------------------------------------------------------------------------
  # fullcalendar example
  setDraggableEvents()
  calendarDate = new Date()
  d = calendarDate.getDate()
  m = calendarDate.getMonth()
  y = calendarDate.getFullYear()
  $(".full-calendar-demo").fullCalendar
    header:
      center: "title"
      left: "basicDay,basicWeek,month"
      right: "prev,today,next"

    buttonText:
      prev: "<span class=\"icon-chevron-left\"></span>"
      next: "<span class=\"icon-chevron-right\"></span>"
      today: "Today"
      basicDay: "Day"
      basicWeek: "Week"
      month: "Month"
    droppable: true
    editable: true
    eventClick: (calEvent, jsEvent, view) ->
      bootbox.confirm "Do you really want to delete selected event?", (result) ->
        $(".full-calendar-demo").fullCalendar('removeEvents', calEvent.id) if result == true
    drop: (date, allDay) ->
      originalEventObject = $(this).data("eventObject")
      originalEventObject.id = Math.floor( Math.random()*99999 )
      console.log originalEventObject
      copiedEventObject = $.extend({}, originalEventObject)
      copiedEventObject.start = date
      copiedEventObject.allDay = allDay
      $(".full-calendar-demo").fullCalendar "renderEvent", copiedEventObject, true
      $(this).remove() if $("#calendar-remove-after-drop").is(":checked")
    events: [
      id: "event1"
      title: "All Day Event"
      start: new Date(y, m, 1)
      className: 'event-orange'
    ,
      id: "event2"
      title: "Long Event"
      start: new Date(y, m, d - 5)
      end: new Date(y, m, d - 2)
      className: "event-red"
    ,
      id: 999
      id: "event3"
      title: "Repeating Event"
      start: new Date(y, m, d - 3, 16, 0)
      allDay: false
      className: "event-blue"
    ,
      id: 999
      id: "event3"
      title: "Repeating Event"
      start: new Date(y, m, d + 4, 16, 0)
      allDay: false
      className: "event-green"
    ,
      id: "event4"
      title: "Meeting"
      start: new Date(y, m, d, 10, 30)
      allDay: false
      className: "event-orange"
    ,
      id: "event5"
      title: "Lunch"
      start: new Date(y, m, d, 12, 0)
      end: new Date(y, m, d, 14, 0)
      allDay: false
      className: "event-red"
    ,
      id: "event6"
      title: "Birthday Party"
      start: new Date(y, m, d + 1, 19, 0)
      end: new Date(y, m, d + 1, 22, 30)
      allDay: false
      className: "event-purple"
    ]
  # --------------------------------------------------------------------------------------------------------------------

  # --------------------------------------------------------------------------------------------------------------------
  # @mention
  if $(".mention").length > 0
    $(".mention").mention users: [
      name: "Lindsay Made"
      username: "LindsayM"
      image: "http://placekitten.com/25/25"
    ,
      name: "Rob Dyrdek"
      username: "robdyrdek"
      image: "http://placekitten.com/25/24"
    ,
      name: "Rick Bahner"
      username: "RickyBahner"
      image: "http://placekitten.com/25/23"
    ,
      name: "Jacob Kelley"
      username: "jakiestfu"
      image: "http://placekitten.com/25/22"
    ,
      name: "John Doe"
      username: "HackMurphy"
      image: "http://placekitten.com/25/21"
    ,
      name: "Charlie Edmiston"
      username: "charlie"
      image: "http://placekitten.com/25/20"
    ,
      name: "Andrea Montoya"
      username: "andream"
      image: "http://placekitten.com/24/20"
    ,
      name: "Jenna Talbert"
      username: "calisunshine"
      image: "http://placekitten.com/23/20"
    ,
      name: "Street League"
      username: "streetleague"
      image: "http://placekitten.com/22/20"
    ,
      name: "Loud Mouth Burrito"
      username: "Loudmouthfoods"
      image: "http://placekitten.com/21/20"
    ]
  # --------------------------------------------------------------------------------------------------------------------

  # --------------------------------------------------------------------------------------------------------------------
  # date, datetime and time pickers

  $("#daterange2").daterangepicker
    format: "MM/DD/YYYY"
  , (start, end) ->
    $("#daterange2").parent().find("input").first().val start.format("MMMM D, YYYY") + " - " + end.format("MMMM D, YYYY")

  $("#daterange").daterangepicker
    ranges:
      Yesterday: [moment().subtract("days", 1), moment().subtract("days", 1)]
      "Last 30 Days": [moment().subtract("days", 29), new Date()]
      "This Month": [moment().startOf("month"), moment().endOf("month")]

    opens: "left"
    format: "MM/DD/YYYY"
    separator: " to "
    startDate: moment().subtract("days", 29)
    endDate: new Date()
    minDate: "01/01/2012"
    maxDate: "12/31/2013"
    locale:
      applyLabel: "Submit"
      fromLabel: "From"
      toLabel: "To"
      customRangeLabel: "Custom Range"
      daysOfWeek: ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]
      monthNames: ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
      firstDay: 1

    showWeekNumbers: true
    buttonClasses: ["btn-danger"]
    dateLimit: false
  , (start, end) ->
    $("#daterange span").html start.format("MMMM D, YYYY") + " - " + end.format("MMMM D, YYYY")
  # --------------------------------------------------------------------------------------------------------------------

  unless localStorage.getItem("content") == null
    $("#color-settings-body-color").attr("href", localStorage.getItem("content"))

  unless localStorage.getItem("contrast") == null
    $('body')[0].className = $('body')[0].className
      .replace(/(^|\s)contrast.*?(\s|$)/g, ' ')
      .replace(/\s\s+/g, ' ')
      .replace(/(^\s|\s$)/g, '');
    $('body').addClass(localStorage.getItem("contrast"))

  $(".color-settings-body-color > a").hover ->
    $("#color-settings-body-color").attr("href", $(this).data("change-to"))
    localStorage.setItem("content", $(this).data("change-to"))

  $(".color-settings-contrast-color > a").hover ->
    $('body')[0].className = $('body')[0].className
      .replace(/(^|\s)contrast.*?(\s|$)/g, ' ')
      .replace(/\s\s+/g, ' ')
      .replace(/(^\s|\s$)/g, '');
    $('body').addClass($(this).data("change-to"))
    localStorage.setItem("contrast", $(this).data("change-to"))

@setDraggableEvents = ->
  $("#events .external-event").each ->
    eventObject = title: $.trim($(this).text())
    $(this).data "eventObject", eventObject
    $(this).draggable
      zIndex: 999
      revert: true
      revertDuration: 0

@setTimeAgoExample = (selector = $("#timeago-example")) ->
  date = new Date()
  months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
  timeago = selector
  timeago.attr("title", "#{months[date.getMonth()]} #{date.getDate()}, #{date.getFullYear()} #{date.getHours()}:#{date.getMinutes()}")
  timeago.text("#{months[date.getMonth()]} #{date.getDate()}, #{date.getFullYear()} #{date.getHours()}:#{date.getMinutes()}")
  timeago.timeago()