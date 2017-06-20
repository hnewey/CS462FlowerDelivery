ruleset edmunds_api {
	meta {
		configure using api_key = ""
		
		provides 
				find_vin, get_mpg
	}
	
	global {
		find_vin = function(vin) {
			base_url = "https://api.edmunds.com/api/vehicle/v2/vins/" + vin + "?fmt=json&api_key=" + api_key;
			json = http:get(base_url) with parseJSON = true;
		}
		get_mpg = function(vin) {
			vehicleJSON = find_vin(vin)
			mpg = vehicleJSON{["MPG", "city"]}
	}
}
