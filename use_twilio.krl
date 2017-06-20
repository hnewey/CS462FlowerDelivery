ruleset use_twilio {
  meta {
    use module twilio_keys 
    use module twilio_api alias twilio
        with account_sid = keys:twilio("account_sid")
             auth_token =  keys:twilio("auth_token")
  }
 
  rule send_sms {
    select when notify new_message
    send_directive ("twilio")
       with twilio = 
    twilio:send_sms(event:attr("to").defaultsTo("+number here"),
                    event:attr("from").defaultsTo("+13852194839"),
                    event:attr("message").defaultsTo("Twilio works")
                   )
  }
}
