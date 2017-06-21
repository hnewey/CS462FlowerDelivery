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
 	      	event:send({
    	      	"eci": "cj4689a42000be1duanmxuinx", "eic": "notify driver",
    	      	"domain": "order", "type": "received",
    	      	"attrs": {
    	        	"orderID": ent:orders{[order, "orderID"]},
								"flowershopECI": meta:eci
	   	      	}
	    	    }.klog("event sent"))

        fired {
            ent:counter := ent:counter + 1;
            ent:orders := ent:orders.defaultsTo({}).put(orderID, orderInfo)
         }

    }

    rule handle_bid {
        select when shop handle_bid
        pre {
            order = event:attr("order_id").klog("order_id: ")
			delivery_charge = event:attr("delivery_charge")
			driver_id = event:attr("driver_id").klog("driver_id is: ")
        }
	if driver_id && ent:orders>< order && ent:orders{[order,"status"]} == "processing" then 
  	      event:send({
    	      "eci": driver_id, "eic": "bid_accepted",
    	      "domain": "driver", "type": "bid_accepted",
    	      "attrs": {
    	        	"orderID": ent:orders{[order, "orderID"]},
								"flowershopECI": meta:eci
	   	      }
    	    }.klog("bid accepted"))
	    fired {
	        twilio:send_sms(ent:orders{[order, "phone"]},
                event:attr("from").defaultsTo("+13852194839"),
                "Your order: " + event:attr("order_id") + " is out for delivery. Your driver " +
				"has estimated a delivery charge of $" + delivery_charge);
            ent:orders{[order]} := ent:orders{[order]}.put("status", "delivering")
        }
    }

    rule finish_job {
        select when shop finish
        pre {
            order = event:attr("orderID")
        }
        if ent:orders >< order then
            noop()
        fired {
	        twilio:send_sms(ent:orders{[order, "phone"]},
                event:attr("from").defaultsTo("+13852194839"),
                "Thank for using our flower shop. Your order has arrived");
            ent:orders{[order]} := ent:orders{[order]}.put("status", "finished")
        }
    }

}
