ruleset twilio_keys {
  meta {
    key twilio {
          "account_sid": "<our account SID here>", 
          "auth_token" : "<our auth token here>"
    }
    provides keys twilio to use_twilio, flower_shop
  }
}
