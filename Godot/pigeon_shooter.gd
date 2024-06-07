extends Node2D

@onready var cd_timer = $CountDownTimer
@onready var game_timer = $GameTimer
@onready var time_left_label = $TimeLeft
@onready var score = $Score
@onready var count_down_label = $CountDown
@onready var animation_player = $Background/AnimationPlayer
@onready var cooldown_progress_bar = $ProgressBar
@onready var player = $Player

@onready var sfx = $SFXs

@onready var clothing_scene = preload("res://clothing.tscn")
@onready var projectile_scene = preload("res://projectile.tscn")

var count_down = 3
var speed = 800
var seconds = 0

var user_id = GameVariables.current_user_id
var http_ready = true
var last_route = ""
var last_method
var last_data
var request_queue = []
var last_user = ""
var last_user_id = -1

var CON = (GameVariables.tenants[GameVariables.visited_pigeon])["con"]
var cooldown_time = 0.0
var cooldown_duration

@export var game_ended = false

func _ready():
	sfx.stream = load("res://Art/SFX/count_downSFX.mp3")
	sfx.volume_db = -20
	sfx.play()
	
	Input.set_custom_mouse_cursor(load("res://Art/1.png"), Input.CURSOR_ARROW)
	Input.set_custom_mouse_cursor(load("res://Art/0.png"), Input.CURSOR_POINTING_HAND)
	$HTTPRequest.request_completed.connect(self._on_request_completed)
	GameVariables.current_score = 0
	
	if CON < 30:
		cooldown_duration = 0.5+float(CON)/100*1.10
	else:
		cooldown_duration = 1.0+float(CON)/100*1.10
	cooldown_progress_bar.max_value = cooldown_duration
	cd_timer.wait_time = 1

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	print(game_ended)
	
	if Input.is_action_just_pressed("Mouse_Left") :
		Input.set_custom_mouse_cursor(load("res://Art/1.png"), Input.CURSOR_POINTING_HAND)
	if Input.is_action_just_released("Mouse_Left"):
		Input.set_custom_mouse_cursor(load("res://Art/0.png"), Input.CURSOR_POINTING_HAND)
		
	if Input.is_action_pressed("left") and player.position.x > 600:
		player.position.x -= speed * delta
	if Input.is_action_pressed("right") and player.position.x < 1300:
		player.position.x += speed * delta
	
	cooldown_time -= delta
	cooldown_progress_bar.value = cooldown_duration - cooldown_time
	
	#have a visual reload bar?
	if Input.is_action_just_pressed("space") and cooldown_time <= 0.0 and game_ended == false:
		sfx.stream = load("res://Art/SFX/shootSFX.wav")
		sfx.volume_db = 0
		sfx.play()
		var projectile = projectile_scene.instantiate()
		projectile.position = Vector2(player.position.x, player.position.y - 120)
		add_child(projectile)
		cooldown_time = cooldown_duration
	
	#måske skal der ikke opdateres hvert sekund?
	score.text = " " + str(GameVariables.current_score)

func _on_timer_timeout():
	if count_down > 1:
		count_down -= 1
		
		count_down_label.text = "[center]Get ready!\n" + str(count_down)
	elif count_down in [1,0]:
		count_down_label.text = "[center]Get ready!\nGo!"
		
		if count_down == 0:
			count_down_label.visible = false   
			cd_timer.wait_time = 2
			game_timer.start()
			time_left_label.visible = true
			score.visible = true
			cooldown_progress_bar.visible = true
		
		count_down -= 1
	else:
		if cd_timer.wait_time > 0.8:
			cd_timer.wait_time -= 0.1
		
		var clothing = clothing_scene.instantiate()
		clothing.position = Vector2(1721,457)
		add_child(clothing)
		
		animation_player.play("woman_throw")
		sfx.stream = load("res://Art/SFX/Cloth_Thrown.wav")
		sfx.volume_db = 0
		sfx.play()

func _on_game_timer_timeout():
	if seconds != 30:
		seconds += 1
		game_timer.start()
		time_left_label.text = "[center]" + str(int(time_left_label.text) - 1)
	else: #game ended
		sfx.stream = load("res://Art/SFX/winSFX.mp3")
		sfx.volume_db = -15
		
		cd_timer.stop()
		#just pretty stuff
		count_down_label.add_theme_font_size_override("normal_font_size",160)
		count_down_label.add_theme_constant_override("shadow_offset_y",30)
		count_down_label.fit_content = true
		
		var old_CHA = (GameVariables.tenants[GameVariables.visited_pigeon])["cha"]
		
		var INT = (GameVariables.tenants[GameVariables.visited_pigeon])["int"]
		
		var added_CHA = ceil(0.5+(float(INT)/20.)*1.001**float(GameVariables.current_score))
		var new_CHA = old_CHA + added_CHA
		var money_earned = int(ceil(float((GameVariables.current_score)**0.75)/8. + 1.002**(GameVariables.current_score)))
		
		count_down_label.text = " Times up!\n[font_size=140] Score: " + str(GameVariables.current_score) + "\n Lvl up! CHA: " + str(old_CHA) + " + " + str(added_CHA) + " = " + str(new_CHA) + "\n Earned " + str(money_earned) + "g" 
		animation_player.play("game_done")
		
		_start_request("/score", HTTPClient.METHOD_PUT,{"game":"shooter","user":user_id,"score":GameVariables.current_score})
		_start_request("/pigeon", HTTPClient.METHOD_PUT,{"pigeon":int(str(GameVariables.visited_pigeon)), "chance": new_CHA, "constitution": CON})
		_start_request("/money", HTTPClient.METHOD_PUT,{"user":user_id, "money": money_earned})


func _on_clothing_line_area_body_entered(body):  #checks if clothing lands on line
	body.landed = true

func _on_return_button_pressed():
	GameVariables.visiting = false
	GameVariables.visited_pigeon = null
	
	_start_request("/load_game", HTTPClient.METHOD_GET, {"user":GameVariables.current_user}) #doesn't work :(

#database stuff
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
	http_ready = true
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
