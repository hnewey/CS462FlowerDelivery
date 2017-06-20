ruleset edmunds_api {
	meta {
		configure using api_key = ""
		
		provides 
				find_vin
	}
	
	global {
		find_vin = function(vin) {
			base_url = "https://api.edmunds.com/api/vehicle/v2/vins/" + vin + "?fmt=json&api_key=" + api_key;
			json = http:get(base_url) with parseJSON = true;
			json{["content", "MPG", "city"]};
      17;
		}
	}
}
