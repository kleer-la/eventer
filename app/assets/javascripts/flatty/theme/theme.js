$(document).ready(function() {
  setScrollable();
  setTimeAgo();
  setAutoSize();
  setCharCounter();
  setMaxLength();
  setValidateForm();
  setSortable($(".sortable"));
  setSelect2();

  // datetimepickers
  $(".datetimepicker").datetimepicker();
  $(".datepicker").datetimepicker({ pickTime: false });
  $(".timepicker").datetimepicker({ pickDate: false });

  // setting up basic wysiwyg
  $('.wysihtml5').wysihtml5();

  // setting up sortable list
  $('.dd').nestable();

  // setting up responsive tabs
  $('.nav-responsive.nav-pills, .nav-responsive.nav-tabs').tabdrop();

  // setting up naked password for password strength
  $("input.nakedpassword").nakedPassword({
    path: "/assets/images/plugins/naked_password/"
  });

  // setting up datatables
  setDataTable($(".data-table"));
  setDataTable($(".data-table-column-filter")).columnFilter();

  // removes .box after click on .box-remove button
  $(".box .box-remove").click(function(e) {
    $(this).parents(".box").first().remove();
    e.preventDefault();
  });

  // hides .box after click on .box-collapse
  $(".box .box-collapse").click(function(e) {
    var box = $(this).parents(".box").first();
    box.toggleClass("box-collapsed");
    e.preventDefault();
  });

  // setting up bootstrap popovers
  $("body").on("mouseenter", ".has-popover", function() {
    var el = $(this);
    if (el.data("popover") === undefined) {
      el.popover({
        placement: el.data("placement") || "top",
        container: "body"
      });
    }
    el.popover("show");
  });

  $("body").on("mouseleave", ".has-popover", function() {
    $(this).popover("hide");
  });

  // setting up bootstrap tooltips
  $("body").on("mouseenter", ".has-tooltip", function() {
    var el = $(this);
    if (el.data("tooltip") === undefined) {
      el.tooltip({
        placement: el.data("placement") || "top",
        container: "body"
      });
    }
    el.tooltip("show");
  });

  $("body").on("mouseleave", ".has-tooltip", function() {
    $(this).tooltip("hide");
  });

  // check all checkboxes in table with class only-checkbox
  $("#check-all").click(function() {
    $(this).parents("table:eq(0)").find(".only-checkbox :checkbox").attr("checked", this.checked);
  });

  // color pickers
  $(".colorpicker-hex").colorpicker({ format: "hex" });
  $(".colorpicker-rgb").colorpicker({ format: "rgb" });

  // modernizr fallbacks
  if (!Modernizr.input.placeholder) {
    $("[placeholder]").focus(function() {
      var input = $(this);
      if (input.val() === input.attr("placeholder")) {
        input.val("");
        input.removeClass("placeholder");
      }
    }).blur(function() {
      var input = $(this);
      if (input.val() === "" || input.val() === input.attr("placeholder")) {
        input.addClass("placeholder");
        input.val(input.attr("placeholder"));
      }
    }).blur();
    $("[placeholder]").parents("form").submit(function() {
      $(this).find("[placeholder]").each(function() {
        var input = $(this);
        if (input.val() === input.attr("placeholder")) {
          input.val("");
        }
      });
    });
  }

  // affixing main navigation
  if (!$("body").hasClass("fixed-header")) {
    $('#main-nav.main-nav-fixed').affix({ offset: 40 });
  }
});

// select2
window.setSelect2 = function(selector) {
  if (!selector) selector = $(".select2");
  selector.each(function(i, elem) {
    $(elem).select2();
  });
};

// form validation
window.setValidateForm = function(selector) {
  if (!selector) selector = $(".validate-form");
  selector.each(function(i, elem) {
    $(elem).validate({
      errorElement: "span",
      errorClass: "help-block error",
      errorPlacement: function(e, t) {
        t.parents(".controls").append(e);
      },
      highlight: function(e) {
        $(e).closest(".control-group").removeClass("error success").addClass("error");
      },
      success: function(e) {
        e.closest(".control-group").removeClass("error");
      }
    });
  });
};

// datatables
window.setDataTable = function(selector) {
  return selector.dataTable({
    sDom: "<'row-fluid'<'span6'l><'span6 text-right'f>r>t<'row-fluid'<'span6'i><'span6 text-right'p>>",
    sPaginationType: "bootstrap",
    oLanguage: {
      sLengthMenu: "_MENU_ records per page"
    }
  });
};

// character max length
window.setMaxLength = function(selector) {
  if (!selector) selector = $(".char-max-length");
  selector.maxlength();
};

// character counter
window.setCharCounter = function(selector) {
  if (!selector) selector = $(".char-counter");
  selector.charCount({
    allowed: selector.data("char-allowed"),
    warning: selector.data("char-warning"),
    cssWarning: "text-warning",
    cssExceeded: "text-error"
  });
};

// autosize feature for expanding textarea elements
window.setAutoSize = function(selector) {
  if (!selector) selector = $(".autosize");
  selector.autosize();
};

// timeago feature converts static time to dynamically refreshed
window.setTimeAgo = function(selector) {
  if (!selector) selector = $(".timeago");
  jQuery.timeago.settings.allowFuture = true;
  jQuery.timeago.settings.refreshMillis = 60000;
  selector.timeago();
  selector.addClass("in");
};

// scrollable boxes
window.setScrollable = function(selector) {
  if (!selector) selector = $(".scrollable");
  selector.each(function(i, elem) {
    $(elem).slimScroll({
      height: $(elem).data("scrollable-height"),
      start: $(elem).data("scrollable-start") || "top"
    });
  });
};

// jquery-ui sortable
window.setSortable = function(selector) {
  if (selector) {
    selector.sortable({
      axis: selector.data("sortable-axis"),
      connectWith: selector.data("sortable-connect")
    });
  }
};
