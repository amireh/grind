grind_ui = function() {
  var handlers = {
    on_entry: []
  };

  return {
    on_entry: function(handler) {
      handlers.on_entry.push(handler);
    },
    add_entry: function(entry) {
      foreach(handlers.on_entry, function(h) { h(entry); });
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

  var us = $("table td[data-name=" + name + "]:contains(" + value + ")"),
      were_highlighted = false;

  if (us.hasClass("highlighted"))
    were_highlighted = true;
  
  $("table td.highlighted").removeClass("highlighted");
  
  if (were_highlighted)
    return;

  us.addClass("highlighted");
}
$(document).ready(function(){

  $("#toggle_feed").click(function() {
    if (grind.is_connected()) {
      grind.disconnect();      
      $(this).attr("data-toggled", null);
    } else {
      $(this).attr("data-toggled", "true");
      grind.connect();
    }

    toggle_alterable($(this));

  }).click();

  ui.on_entry(function(row) {
    row.find("td[data-name]").click(function() {
      highlight($(this).attr("data-name"), $(this).html());
    });
  });

});