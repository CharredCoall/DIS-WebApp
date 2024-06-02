extends Node

var http_ready := true
var last_route := ""
var last_method 


# Called when the node enters the scene tree for the first time.
func _ready():
	$HTTPRequest.request_completed.connect(self._on_request_completed)
	$Label.text = GameVariables.current_user + " " + str(GameVariables.current_user_id)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _open_logintab():
	$LoginTab/LoginAnimation.play("ZoomLoginTab")


func _close_logintab():
	$LoginTab/LoginAnimation.play_backwards("ZoomLoginTab")


func _start_request(route, method, data):
	if http_ready :
		last_route = route
		last_method = method
		var error
		if method == HTTPClient.METHOD_GET :
			var query_string = "?"
			for i in range(len(data)):
				if i != 0:
					query_string += "&"
				query_string += data.keys()[i] + "=" + data[data.keys()[i]] 
			error = $HTTPRequest.request(GameVariables.url + route + query_string, ["Content-Type: application/json","Cookie: " + GameVariables.cookie], method)
		else:
			error = $HTTPRequest.request(GameVariables.url + route, ["Content-Type: application/json","Cookie: " + GameVariables.cookie], method, JSON.stringify(data))
		if error != OK:
			push_error("An error occurred in the HTTP request.")
		http_ready = false
	
func _on_request_completed(result, response_code, headers, body):
	http_ready = true
	if response_code != 200:
		print(body.get_string_from_utf8())
		return
	var header_dict = {}
	var regex = RegEx.new()
	regex.compile(r"(\b[^:]*\b): (.*)")
	for header in headers:
		result = regex.search(header)
		header_dict[result.get_string(1)] = result.get_string(2) 
	if 'Set-Cookie' in header_dict :
		GameVariables.cookie = header_dict['Set-Cookie']
	var body_string = body.get_string_from_utf8()
	var json = JSON.parse_string(body_string)
	if last_route == "/user" && last_method == HTTPClient.METHOD_PUT:
		if json :
			_start_request("/load_game",HTTPClient.METHOD_GET, {"user": $LoginTab/UsernameField.text})
	elif last_route == "/load_game" :
		GameVariables.current_user = json["userData"][1]
		GameVariables.current_user_id = json["userData"][0]
		GameVariables.data = json
		var pigeonholes := {}
		for pigeonhole in json['pigeonholes']:
			pigeonholes[int(pigeonhole[0])] = _dbpos_to_gamepos(pigeonhole[1])
		GameVariables.pigeonholes = pigeonholes
		for pigeon in json['pigeons']:
			if pigeon[5] != null:
				pigeon[5] = int(pigeon[5])
				GameVariables.pigeon_clothes[str(pigeon[0])] = GameVariables.store_items[int(pigeon[5])][0]
			GameVariables.tenants[str(pigeon[0])] = {"pos": pigeonholes[int(pigeon[1])], "state": "idle", "con": pigeon[2], "int": pigeon[3], "cha": pigeon[4], "hat": pigeon[5]} 
		GameVariables.money = json["userData"][2]
		GameVariables.items = {}
		for hat in json['hats']:
			if hat[1] > 0:
				GameVariables.items[int(hat[0])] = hat[1]
		get_tree().change_scene_to_file("res://hotel.tscn")
	elif last_route == "/user" && last_method == HTTPClient.METHOD_POST:
			_start_request("/load_game",HTTPClient.METHOD_GET, {"user": $LoginTab/UsernameField.text})
		
	
			
			
			
			
func _dbpos_to_gamepos(pos):
	var translate_list = [Vector2(600,260),Vector2(1432,810),Vector2(1430,270)]
	return translate_list[pos]
			
			
			
			
			
			
			 
