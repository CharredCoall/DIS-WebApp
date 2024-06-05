extends Node

@onready var announce_label = $AnnounceLabel
@onready var score_label = $ScoreLabel
@onready var level_up_label = $LevelUpLabel
@onready var money_label = $MoneyLabel
@onready var goober = $Goober/AnimatedGoober

var score:int
var con:int
var chance:int
var money:int
var user_id = GameVariables.current_user_id
var http_ready = true
var last_route = ""
var last_method
var last_data
var request_queue

#_start_request("/score", HTTPClient.METHOD_PUT,{"game":"clicker","user":user_id,"score":score}) #Update Score
#_start_request("/pigeon", HTTPClient.METHOD_PUT,{"pigeon":int(str(GameVariables.visited_pigeon.get_name())), "chance":chance,"constitution":con}) #Update Stats

func set_score(new_score):
	score = new_score
	money = int(20. + ceil(float(score)**0.9/5.))

func level_up(oldcon:int, intelligence:int):
	con = round(oldcon + (float(intelligence)/20.)*score**0.25)

func display_stuff(oldcon:int):
	announce_label.text = "Times Up!"
	score_label.text = "You got " + str(score) + " Points!"
	level_up_label.text = "You leveled up! Con:"  + str(oldcon) + "+" + str(con-oldcon)
	money_label.text = "You gained " + str(money) + "coins!"
	goober.play("Munch")

func _on_go_back_to_menu_pressed():
	make_requests()
	get_tree().change_scene_to_file("res://hotel.tscn")

func make_requests():
	_start_request("/score", HTTPClient.METHOD_PUT,{"game":"clicker","user":user_id,"score":score}) #Update Score
	_start_request("/pigeon", HTTPClient.METHOD_PUT,{"pigeon":int(str(GameVariables.visited_pigeon.get_name())), "chance":chance,"constitution":con}) #Update Stats
	#_start_request({}) #Update Money!!

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
	var request = request_queue.pop_front()
	if request != null :
		_start_request(request["route"], request["method"], request["data"])

