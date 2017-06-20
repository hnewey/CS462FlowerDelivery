// to send a new order 
//   select when order received
//       flowershopId = event:attr("flowershopId").klog("flowershopId")
//       order = event:attr("orderNumber").klog("order")
//       address = event:attr("address").klog("address")
//       order = event:attr("order").klog("order")
The 

ruleset gossip {
  meta {
    name "gossip"
    use module io.picolabs.pico alias wrangler
    use module Subscriptions
		use module edmunds_keys
		use module edmunds_api
										with api_key = keys:edmunds("api_key")
    shares allMessages, unorgMessages, listSchedule
  }
  global {
    getProposal = function () {
			proposal = edmunds_api:find_vin("JNKCV51E06M521497")
    }
    allMessages = function() {
      ent:all_messages.unique().filter(function(x){not x.isnull()})
    }
    unorgMessages = function() {
      ent:messages
    }
    getPeer = function(){
      subscriptions = Subscriptions:getSubscriptions();
      subscriptions{[subscriptions.keys()[random:integer(0,subscriptions.keys().length())]]}
    }
    listSchedule = function() {
      schedule:list()
    }
    myFunc = function(){
      10
    }
    getSeen = function(){
      ent:messages.defaultsTo([]).map(function(v,k) {
        v.length()
        
      })
    }
    turn_off_listener = function(){
      schedule:list().map(function(x) {
        schedule.remove(x.id).klog("x")
      })
    }
    add_message = function(message, messages){
      parts = message{["MessageID"]}.split(re#:#);
      parts.klog("parts");
      messages{[parts[0]]} = messages{[parts[0]]} || [];
      messages{[parts[0]]} = messages{[parts[0]]}.length() == parts[1].as("Number") =>
          messages{[parts[0]]}.append(message)
          | messages{[parts[0]]};
      messages.klog("new messagessss")
    }
    add_messages = function(queue, messages) {
      queue.klog("queue");
      // messages = ent:messages.defaultsTo({});
      queue.map(function(message){
        parts = message{["MessageID"]}.split(re#:#).klog("parts");
        messages{[parts[0]]} = (messages{[parts[0]]} || []).klog("array");
        messages{[parts[0]]} = messages{[parts[0]]}.length() == parts[1].as("Number") =>
          messages{[parts[0]]}.append(message)
          | messages{[parts[0]]};
          messages.klog("messages here");
        0
      });
      messages.klog("new messagessss")
    }
    get_work_queue = function(seen) {
      slice_arr = function(mylist, last_seen) {
        last_seen >= mylist.length() => [] | mylist.slice(last_seen, mylist.length().klog("length I have")).klog("new list")
      };
      ent:messages.klog("messages").keys().map(function(k){
        seen.klog("seen in work queue").keys().has([k]) => slice_arr(ent:messages{[k]}, seen{[k]}).klog("missing messages") | ent:messages{[k]}.klog("else")
      }).reduce(function(a,b){a.append(b)})
    }
  }
  rule receive_message {
    select when order received
    pre {
      flowershopId = event:attr("flowershopId").klog("flowershopId")
      order = event:attr("orderNumber").klog("order")
      address = event:attr("address").klog("address")
      order = event:attr("order").klog("order")
    }
    always {
      
      ent:messages := ent:messages.defaultsTo({});
      ent:messages{[flowershopId]} := ent:messages{[flowershopId]}.defaultsTo([]);
      message = {"MessageID": flowershopId + ":" + ent:messages{[flowershopId]}.length(),
                 "flowershopId": flowershopId, "order": order, "address": address};
      ent:all_messages := ent:all_messages.defaultsTo([]).append(message);
      ent:messages{[flowershopId]} := ent:messages{[flowershopId]}.append(message)
    }
  }
  rule gossip_switch {
    select when process gossip_switch
    pre {
      attributes = event:attrs()
      status = event:attr("status")
      already_on = ent:already_on.defaultsTo(false).klog("already_on")
    }
    if not status.isnull() && status.as("Boolean").klog("status") != already_on 
    then  send_directive("changing status")
      with status = status
    
    fired {
      ent:messages := ent:messages.defaultsTo({});
      ent:already_on := status.as("Boolean");
      raise gossip event "timer" attributes attributes      
    }

  }
  rule gossip_timer {
    select when gossip activate
    pre {
      activated = ent:activated.defaultsTo(false)
      sub = Subscriptions:getSubscriptions().klog("subscriptions")
    }
    if not activated.as("Boolean") then
      send_directive("turning on timer")
    fired {
      ent:messages := ent:messages.defaultsTo({});
      ent:activated := true;
      schedule gossip event "wakeup" repeat "*/5 * * * * *"
    }
  }

  rule wakeup {
    select when gossip wakeup
    pre {
      on = ent:already_on
      id = meta:picoId.klog("id")
    }
    if on then send_directive("checking")
    fired {
      raise gossip event "check"
        attributes event:attrs()
    }
  }
  rule check {
    select when gossip check 
    pre {
      // q = myFunc().klog("func")
      subscriber = getPeer().klog("peer97")
      seen = getSeen().klog("seen")
    }
    event:send(
      {"eci":subscriber{["attributes","outbound_eci"]}, "eic": "gossip",
      "domain": "gossip", "type": "seen",
      "attrs": {
        "message": seen,
        "eci": meta:eci,
        "host": meta:host
      }
   })

  }
  rule auto_accept {
    select when wrangler inbound_pending_subscription_added
    pre {
      attributes = event:attrs().klog("subcription:")
    }
    always {
      raise wrangler event "pending_subscription_approval"
        attributes attributes
    }
  }
  rule auto_accept2 {
    select when wrangler outbound_pending_subscription_added
    pre {
      attributes = event:attrs().klog("subcription:")
    }
    always {
      raise wrangler event "pending_subscription_approval"
        attributes attributes
    }
  }
  rule set_subscription {
    select when gossip subscribe
    pre {
      eci = meta:eci
      my_host = meta:host
      host = event:attr("host").defaultsTo(my_host)
      subscriber = event:attr("subscriber")
    }
    always {
      raise wrangler event "subscription"
        with name = subscriber+eci
         name_space = "mischief"
         my_role = "peer"
         subscriber_role = "peer"
         channel_type = "subscription"
         subscriber_eci = subscriber
         subscriber_host = host.klog("host")
    }
    // event:send(
    //   {"eci": eci, "eic": "subscription",
    //     "domain": "wrangler", "type": "subscription",
    //     "attrs": {
    //       "name": eci + subscriber,
    //       "name_space": "gossip",
    //       "my_role": "peer",
    //       "subscriber_role": "peer",
    //       "channel_type": "subscription",
    //       "subscriber_host": host,
    //       "subscriber_eci": subscriber
    //     }}
    // )
  }
  // rule is_seen {
  //   select when gossip seen
  //   pre {
  //     message = event:attr("message").klog("attrs")
  //     eci = event:attr("eci") 
  //     host = event:attr("host").defaultsTo(meta:host)
  //     queue = get_work_queue(message)
  //   }
  //   if queue.length() > 0 then
  //       event:send({
  //         "eci": eci, "eic": "gossip",
  //         "domain": "gossip", "type": "rumor",
  //         "attrs": {
  //           "message": queue
  //         }
  //       }, host)
  // }
  rule is_seen {
    select when gossip seen
    foreach get_work_queue(event:attr("message").klog("message with seen")) setting (message)
    pre {
      // message = event:attr("message").klog("attrs")
      eci = event:attr("eci") 
      host = event:attr("host").defaultsTo(meta:host)
      // queue = get_work_queue(message)
    }
    // if queue.length() > 0 then
        event:send({
          "eci": eci, "eic": "gossip",
          "domain": "gossip", "type": "rumor",
          "attrs": {
            "message": message
          }
        }, host)
  }
  rule is_rumor {
    select when gossip rumor
    pre {
      message = event:attr("message").klog("queue")
      messages = ent:messages.defaultsTo({})
      // o = add_messages(queue, messages)
      new_messages = add_message(message, messages)
    }
    always {
      ent:messages := new_messages;
      ent:all_messages := ent:all_messages.defaultsTo([]).append(message)
    }
  }
	rule place_bid {
		select when driver bid
		pre {
			delivery_charge = getProposal()
			order_id = event:attr("orderID")
			//flowershop_id = ""  **Set flowershop pico eci here
		}
        event:send({
          "eci": flowershop_id, "eic": "bid",
          "domain": "shop", "type": "handle_bid",
          "attrs": {
            "delivery_charge": delivery_charge, "order_id": order_id, "driver_id": meta:eci
          }
        })

}
