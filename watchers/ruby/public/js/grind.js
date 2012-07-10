foreach = function(arr, handler) {
  arr = arr || []; for (var i = 0; i < arr.length; ++i) handler(arr[i]);
}
log = function(m, ctx) { ctx = ctx || "D"; console.log("[" + ctx + "] " + m); }

grind = function() {
  var groups = {},
      handlers = {
        on_connected: [],
        on_disconnected: [],
        on_message: [],
        on_command: {}
      },
      socket = null,
      host = "127.0.0.1",
      port = "8181",
      connected = false;


  function ws_onmessage(evt) {
    var feed = null;
    try {
      feed = JSON.parse(evt.data)
    } catch(err) {
      log("BAD DATA: " + err, "E")
      return;
    }

    console.log(feed);
    if (typeof(feed) == "object" && feed.command) {
      handle_cmd(feed);
      return;
    }

    // for (var i =0; i < feed.length; ++i) {
      foreach(handlers.on_message, function(e) { e(feed); });
    // }


    //   var msg = feed[i];
    //   $("table tbody").append("<tr></tr>");
    //   var tr = $("table tbody tr:last");
    //   tr.append("<td>" + msg.meta.timestamp + "</td>");
    //   tr.append("<td>" + msg.meta.fqdn + "</td>");
    //   tr.append("<td>" + msg.meta.app + "</td>");
    //   tr.append("<td>" + msg.meta.context + "</td>");
    //   tr.append("<td>" + msg.meta.uuid + "</td>");
    //   tr.append("<td>" + msg.meta.module + "</td>");
    //   tr.append("<td>" + msg.body + "</td>");
    //   // $("#msg").append("<p>"+evt.data+"</p>");
      
    // }
  };

  function ws_onclose() { 
    connected = false;
    log("Disconnected.");
    foreach(handlers.on_disconnected, function(h) { h(); });
  };

  function ws_onopen() {
    connected = true;
    log("Connected.")
    foreach(handlers.on_connected, function(h) { h(); });
  };

  function send_cmd(cmd) {
    if (!connected) {
      return log("Unable to dispatch command '" + cmd + "'; grind isn't connected!", "E");
    }

    log("Sending command " + cmd.id)    
    console.log(cmd)    
    socket.send(JSON.stringify(cmd));    
    // socket.send(cmd);    
  }

  function handle_cmd(msg) {
    switch(msg.command) {
      case "list_groups":
        for (var i=0; i < msg.result.length; ++i) {
          groups[msg.result[i]] = {};
        }
        break;
    }

    foreach(handlers.on_command[msg.command], function(h) { h(msg) });
  }

  return {
    // log: log,
    // this: this,
    connect: function() {
      if (connected)
        return;

      socket = new WebSocket("ws://127.0.0.1:8181/websocket");
      socket.onopen = ws_onopen;            
      socket.onclose = ws_onclose;            
      socket.onmessage = ws_onmessage;
    },
    disconnect: function() {
      if (!connected)
        return;

      socket.close();
    },
    is_connected: function() { return connected; },

    // connection bindings
    on_connected: function(handler) {
      handlers.on_connected.push(handler)
    },
    on_disconnected: function(handler) {
      handlers.on_disconnected.push(handler)
    },
    on_message: function(handler) { 
      handlers.on_message.push(handler)
    },

    subscribe: function(group, klass, view, handler) {
      grind.dispatch("subscribe", { group: group, klass: klass, view: view }, handler);
    },

    // command bindings
    on_command: function(cmd, handler) { 
      handlers.on_command[cmd] = handlers.on_command[cmd] || [];
      handlers.on_command[cmd].push(handler);
    },

    dispatch: function(cmd, args, handler) {
      args = args || {};

      if (handler) {
        this.on_command(cmd, handler);
      }
      send_cmd({ id: cmd, args: args });

      return this;
    }

  } // grind():return
}
