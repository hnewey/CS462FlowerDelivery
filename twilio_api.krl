ruleset twilio_api {
  meta {
    configure using account_sid = ""
                    auth_token = ""
    provides
        send_sms
  }
 
  global {
    send_sms = defaction(to, from, message) {
       base_url = <<https://#{account_sid}:#{auth_token}@api.twilio.com/2010-04-01/Accounts/#{account_sid}/>>
       http:post(base_url + "Messages.json")
            with form = {
                "To":to,
                "From":from,
                "Body":message
            }
    }
  }
}

