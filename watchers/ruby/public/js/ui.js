var highlighted = false;
var focused = false;
var last_highlight = null;
// credit goes to: http://www.codetoad.com/javascript_get_selected_text.asp
function get_selected_text()
{
  var txt = '';
  if (window.getSelection) {
    txt = window.getSelection();
  } else if (document.getSelection) {
    txt = document.getSelection();
  } else if (document.selection) {
    txt = document.selection.createRange().text;
  } else 
    return null;

  return txt;
}

grind_ui = function() {
  var handlers = {
    on_entry: []
  };
  var status_timer = null;
  var anime_dur = 250;
  var status_shown = false;
  var status_queue = [];
  var defaults = {
    status_bar: 1.5
  };

  return {
    on_entry: function(handler) {
      handlers.on_entry.push(handler);
    },
    add_entry: function(entry) {
      foreach(handlers.on_entry, function(h) { h(entry); });
    },
    clear_status: function(cb) {
      if (!$("#status_bar").is(":visible"))
        return (cb || function() {})();

      $("#status_bar").hide("slide", {}, anime_dur, function() {
        status_shown = false;
        
        if (cb)
          cb();

        if (status_queue.length > 0) {
          var status = status_queue.pop();
          return ui.status(status[0], status[1], status[2]);
        }
      });
      // $("#status_bar").html("");
    },
    status: function(text, status, seconds_to_show) {
      if (!status)
        status = "notice";
      if (!seconds_to_show)
        seconds_to_show = defaults.status_bar;

      if (status_shown) {
        return status_queue.push([ text, status, seconds_to_show ]);
      }

      if (status_timer)
        clearTimeout(status_timer)

      ui.clear_status(function() {
        status_timer = setTimeout("ui.clear_status()", seconds_to_show * 1000);
        $("#status_bar").removeClass("notice error").addClass(status).html(text).show("slide", {}, anime_dur);
        status_shown = true;
      });

    }
  }
}

toggle_alterable = function(el) {
  var el = $(el);

  if (el.attr("data-alt-text")) {
    var val = el.html();
    el.html(el.attr("data-alt-text"));
    el.attr("data-alt-text", val);
  }

  if (el.attr("data-alt-class")) {
    var old_classes = el.attr("class");
    el.removeClass(old_classes);
    el.addClass(el.attr("data-alt-class"));
    el.attr("data-alt-class", old_classes);
  }
}

highlight = function(name, value) {
  console.log("Highlighting all " + name + " columns with a value of: " + value)

  var us = [], were_highlighted = false;
  $("table td[data-name=" + name + "]").each(function() {
    if ($(this).html() == value)
      us.push($(this).get(0));
  });
  us = $(us);

  if (us.length == 0) {
    highlighted = null;
    return;
  }

  if (us.hasClass("highlighted"))
    were_highlighted = true;
  
  $("table .highlighted").removeClass("highlighted");
  
  if (were_highlighted) {
    return dehighlight();
  }

  us.addClass("highlighted");
  us.each(function() { $(this).parent().addClass("highlighted"); });

  $("#highlighted").html($("#highlighted").html().replace(/\d+/, us.length));
  highlighted = { name: name, value: value };
}
dehighlight = function() {
  $("#highlighted").html($("#highlighted").html().replace(/\d+/, 0));
  last_highlight = highlighted;
  highlighted = null;
  $("tbody .highlighted").removeClass("highlighted");
}
focus = function() {
  if (!highlighted)
    return;

  $("table tbody tr:not(.highlighted)").hide();
  focused = true;
}
reset_focus = function() {
  if (!focused)
    return;

  $("table tbody tr:not(.highlighted)").show();
  focused = false;
}

function is_highlighted() { return highlighted; }
function get_highlight() { return highlighted || last_highlight; }

function is_focused() { return focused; }


$(document).ready(function(){
  $("[data-alt-text],[data-alt-class]").click(function() { toggle_alterable($(this)); });

  $("#connect").click(function() {
    if (grind.is_connected()) {
      grind.disconnect();      
      // $(this).attr("data-toggled", null);
    } else {
      // $(this).attr("data-toggled", "true");
      grind.connect();
    }

    // toggle_alterable($(this));

  });

  ui.on_entry(function(row) {
    row.find("td[data-name]").click(function() {
      highlight($(this).attr("data-name"), $(this).html());
    });
  });

  $("[data-togglable]").click(function() {
    $(this).toggleClass("toggled");
    var alt = $(this).attr("data-togglable");
    if (typeof alt == "string" && alt.length != 0) {
      var current = $(this).html();
      $(this).html(alt);
      $(this).attr("data-togglable", current);
    }
  })
});