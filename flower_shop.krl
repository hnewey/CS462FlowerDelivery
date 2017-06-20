ruleset flower_shop {
    meta {

    }

    global {

    }

    rule new_order {
        select when shop new_order
        pre {
            flower = event:attr("flower")
            phone = event:attr("phone")
            address = event:attr("address")
            orderID = random:uuid();
            orderInfo = {
                "orderID": orderID,
                "flower": flower,
                "phone": phone,
                "address": address,
                "status": "processing"
            }
        }
        if flower && phone && address then
            noop()

        fired {
            ent:orders := ent:orders.defaultsTo({}).put(orderID, orderInfo);
            //todo send broadcast to drivers
        }

    }

    rule handle_bid {
        select when shop handle_bid
        pre {
            order = ent:orders{event:attr("order_id")}
						delivery_charge = event:attr("delivery_charge")
						driver_id = event:attr("driver_id")
        }
				if driver_id then {
  	      event:send({
    	      "eci": driver_id, "eic": "bid_accepted",
    	      "domain": "driver", "type": "bid_accepted",
    	      "attrs": {
    	        "order": order
	   	      }
    	    })
				}
				fired {
					raise notify event "new_message"
						attributes { "message": "Your order: " + event:attr("order_id") + " is out for delivery. Your driver " +
													"has estimated a delivery charge of $" + delivery_charge 
													 }
				}
    }

    rule finish_job {

    }

}
