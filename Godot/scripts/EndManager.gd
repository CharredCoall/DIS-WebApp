extends Node

@onready var announce_label = $AnnounceLabel
@onready var score_label = $ScoreLabel
@onready var level_up_label = $LevelUpLabel
@onready var money_label = $MoneyLabel
@onready var goober = $Goober/AnimatedGoober
@onready var sfx = $"../SFXs"

var score:int
var con:int
var money:int
var user = GameVariables.current_user
var user_id = GameVariables.current_user_id
var http_ready = true
var last_route = ""
var last_method
var last_data
var request_queue : = []

#_start_request("/score", HTTPClient.METHOD_PUT,{"game":"clicker","user":user_id,"score":score}) #Update Score
#_start_request("/pigeon", HTTPClient.METHOD_PUT,{"pigeon":int(str(GameVariables.visited_pigeon.get_name())), "chance":chance,"constitution":con}) #Update Stats
func _ready():
	
	Input.set_custom_mouse_cursor(load("res://Art/1.png"), Input.CURSOR_ARROW)
	Input.set_custom_mouse_cursor(load("res://Art/0.png"), Input.CURSOR_POINTING_HAND)
	$HTTPRequest.request_completed.connect(self._on_request_completed)

func _process(delta):
	if Input.is_action_just_pressed("Mouse_Left") :
		Input.set_custom_mouse_cursor(load("res://Art/1.png"), Input.CURSOR_POINTING_HAND)
	if Input.is_action_just_released("Mouse_Left"):
		Input.set_custom_mouse_cursor(load("res://Art/0.png"), Input.CURSOR_POINTING_HAND)

func set_score(new_score):
	score = new_score
	money = int(20. + ceil(float(score)**0.9/5.))

func level_up(oldcon:int, intelligence:int):
	con = int(round(oldcon+ 0.5 + (float(intelligence)/20.)*1.005**score))

func display_stuff(oldcon:int):
	announce_label.text = "Times Up!"
	score_label.text = "You got " + str(score) + " Points!"
	level_up_label.text = "You leveled up! Con: "  + str(oldcon) + " + " + str(con-oldcon)
	money_label.text = "You gained " + str(money) + "g"
	goober.play("Munch")

func _on_go_back_to_menu_pressed():
	sfx.stream = load("res://Art/SFX/clickSFX.wav")
	sfx.play()
	make_requests()
	_start_request("/load_game", HTTPClient.METHOD_GET,{"user":user})

func make_requests():
	_start_request("/score", HTTPClient.METHOD_PUT,{"game":"clicker","user":user_id,"score":score}) #Update Score
	_start_request("/pigeon", HTTPClient.METHOD_PUT,{"pigeon":int(str(GameVariables.visited_pigeon)), "chance":GameVariables.tenants[str(GameVariables.visited_pigeon)]["cha"],"constitution":con}) #Update Stats
	_start_request("/money", HTTPClient.METHOD_PUT,{"user":user_id,"money":money}) #Update Money!!

#Send HTTP Request to server
func _start_request(route, method, data):
	if http_ready :
		last_route = route
		last_method = method
		last_data = data
		var error
		if method == HTTPClient.METHOD_GET :
			var query_string = "?"
			for i in range(len(data)):
				if i != 0:
					query_string += "&"
				query_string += str(data.keys()[i]) + "=" + str(data[data.keys()[i]]) 
			error = $HTTPRequest.request(GameVariables.url + route + query_string, ["Content-Type: application/json","Cookie: " + GameVariables.cookie], method)
		else:
			error = $HTTPRequest.request(GameVariables.url + route, ["Content-Type: application/json","Cookie: " + GameVariables.cookie], method, JSON.stringify(data))
		if error != OK:
			push_error("An error occurred in the HTTP request.")
		http_ready = false
	else:
		request_queue.append({"route": route, "method": method, "data": data})

#Handle response data from HTTP Request
func _on_request_completed(result, response_code, headers, body):
	if response_code != 200:
		print(body.get_string_from_utf8())
		return
	var header_dict = {}
	var regex = RegEx.new()
	regex.compile(r"(\b[^:]*\b): ?(.*)")
	for header in headers:
		result = regex.search(header)
		header_dict[result.get_string(1)] = result.get_string(2) 
	if 'Set-Cookie' in header_dict :
		GameVariables.cookie = header_dict['Set-Cookie']
	http_ready = true
	var body_string = body.get_string_from_utf8()
	var json = JSON.parse_string(body_string)
	match last_route: 
		"/load_game":
			GameVariables.current_user = json["userData"][1]
			GameVariables.current_user_id = json["userData"][0]
			GameVariables.data = json
			GameVariables.visited_pigeon = null
			var pigeonholes := {}
			for pigeonhole in json['pigeonholes']:
				pigeonholes[int(pigeonhole[0])] = _dbpos_to_gamepos(pigeonhole[1])
			GameVariables.pigeonholes = pigeonholes
			for pigeon in json['pigeons']:
				if pigeon[5] != null:
					pigeon[5] = int(pigeon[5])
					GameVariables.pigeon_clothes[str(pigeon[0])] = GameVariables.store_items[int(pigeon[5])][0]
				GameVariables.tenants[str(pigeon[0])] = {"pos": pigeonholes[int(pigeon[1])], "state": "idle", "con": pigeon[4], "int": pigeon[3], "cha": pigeon[2], "hat": pigeon[5]} 
			GameVariables.money = json["userData"][2]
			GameVariables.items = {}
			for hat in json['hats']:
				if hat[1] > 0:
					GameVariables.items[int(hat[0])] = hat[1]
			get_tree().change_scene_to_file("res://hotel.tscn")
		_:
			var request = request_queue.pop_front()
			if request != null :
				_start_request(request["route"], request["method"], request["data"])

func _dbpos_to_gamepos(pos):
	var translate_list = [Vector2(600,260),Vector2(1432,810),Vector2(1430,270)]
	return translate_list[pos]
