ruleset flower_shop {
    meta {
      use module twilio_keys
      use module twilio_api alias twilio
          with account_sid = keys:twilio("account_sid")
               auth_token =  keys:twilio("auth_token")
    }

    global {

    }

    rule new_order {
        select when shop new_order
        pre {
            flower = event:attr("flower")
            phone = event:attr("phone").defaultsTo("+18014739251")
            address = event:attr("address")
            orderID = ent:counter.defaultsTo(0)
            orderInfo = {
                "orderID": orderID,
                "flower": flower,
                "phone": phone,
                "address": address,
                "status": "processing"
            }
        }
        fired {
            ent:counter := ent:counter + 1;
            ent:orders := ent:orders.defaultsTo({}).put(orderID, orderInfo)
  	      	event:send({
    	      	"eci": "cj4689a42000be1duanmxuinx", "eic": "notify driver",
    	      	"domain": "order", "type": "received",
    	      	"attrs": {
    	        	"orderID": ent:orders{[order, "orderID"]},
								"flowershopECI": meta:eci
	   	      	}
	    	    });
        }

    }

    rule handle_bid {
        select when shop handle_bid
        pre {
            order = event:attr("order_id")
			delivery_charge = event:attr("delivery_charge")
			driver_id = event:attr("driver_id")
        }
	    if driver_id && ent:orders>< order && ent:orders{[order,"status"]} == "processing" then {

  	      event:send({
    	      "eci": driver_id, "eic": "bid_accepted",
    	      "domain": "driver", "type": "bid_accepted",
    	      "attrs": {
    	        	"orderID": ent:orders{[order, "orderID"]},
								"flowershopECI": meta:eci
	   	      }
    	    });
	    }
	    fired {
	        twilio:send_sms(ent:orders{[order, "phone"]},
                event:attr("from").defaultsTo("+13852194839"),
                "Your order: " + event:attr("order_id") + " is out for delivery. Your driver " +
				"has estimated a delivery charge of $" + delivery_charge);
            ent:orders{[order]} := ent.orders{[order,"status"]}.put{"delivering"}
        }
    }

    rule finish_job {
        select when shop finish
        pre {
            order = event:attr("order")
        }
        if ent:orders >< order then
            noop()
        fired {
            ent:orders{[order]} := ent:orders{[order,"status"]}.put{"finished"}
        }
    }

}
