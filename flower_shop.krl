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

    rule make_bid {
        select when shop make_bid
        pre {
            order = event:attr("order")

        }
    }

    rule finish_job {

    }

}
