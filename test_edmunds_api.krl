ruleset test_edmunds_api {
	meta {
		use module edmunds_keys
		use module edmunds_api
				with api_key = keys:edmunds("api_key")
	}

	rule test_api {
		select when test vin
    send_directive("VIN") with
				VIN = edmunds_api:find_vin(event:attr("vin").defaultsTo("JNKCV51E06M521497"))
	}
}
