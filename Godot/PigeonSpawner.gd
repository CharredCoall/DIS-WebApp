extends Node2D

@onready var pigeon_scene = preload("res://pigeon.tscn")

@onready var timer = $Timer
@onready var camera = $Camera2D
@onready var back_button = $Camera2D/BackButton
@onready var accessory_button = $Camera2D/AccessoryButton
@onready var accessory_area = $Camera2D/AccessoryButton/AccessoriesArea
@onready var minigames_button = $Camera2D/MinigamesButton
@onready var shooter_button = $Camera2D/MinigamesButton/ShooterButton
@onready var clicker_button = $Camera2D/MinigamesButton/ClickerButton
@onready var stats_button = $Camera2D/StatsButton
@onready var stats_area = $Camera2D/StatsButton/StatsArea
@onready var stats_text = $Camera2D/StatsButton/StatsText
@onready var delete = $Camera2D/Delete
@onready var shop = $Shop

@onready var sfx = $SFXs

@onready var item_list = $Camera2D/AccessoryButton/ItemList

@export var speed = 5

#fix
var rooms = [Vector2(600,260),Vector2(1432,810),Vector2(1430,270)]
var full_rooms = []

var new_pig = null
var clicked_pig

var landed = false

var pigeon_spawned = false
var room_pos = null
var standing_spot = null
	
var http_ready := true
var last_route := ""
var last_method 
var last_data
var request_queue := []
# Called when the node enters the scene tree for the first time.
func _ready():
	Input.set_custom_mouse_cursor(load("res://Art/1.png"), Input.CURSOR_ARROW)
	Input.set_custom_mouse_cursor(load("res://Art/0.png"), Input.CURSOR_POINTING_HAND)
	
	if GameVariables.current_user_id == -1:
		get_tree().change_scene_to_file("res://login.tscn")
		return
	else:
		rooms = [Vector2(600,260),Vector2(1432,810),Vector2(1430,270)]
		full_rooms = []
		$HTTPRequest.request_completed.connect(self._on_request_completed)
		timer.wait_time = randi_range(5,20)
		timer.start()

		for item in GameVariables.items:
			item_list.add_icon_item(load(GameVariables.store_items[item][0]))
			
		_place_pigeons()
		
func _place_pigeons():
	for saved_pig in GameVariables.tenants:
		var the_pig = pigeon_scene.instantiate()
		the_pig.position = GameVariables.tenants[saved_pig]["pos"]
		standing_spot = GameVariables.tenants[saved_pig]["pos"]
		full_rooms.append(GameVariables.tenants[saved_pig]["pos"])
		rooms.erase(GameVariables.tenants[saved_pig]["pos"])
		add_child(the_pig)
		move_child(the_pig,-2)
		the_pig.name = saved_pig
		if GameVariables.tenants[saved_pig].has("hat"):
			if GameVariables.tenants[saved_pig]["hat"] != null:
				the_pig.get_node("AnimatedSprite2D/Accessory").texture = load(GameVariables.store_items[GameVariables.tenants[saved_pig]["hat"]][0]) 
			the_pig.pigeon_clicked.connect(self._on_pigeon_clicked)

func _process(_delta):
	if Input.is_action_just_pressed("Mouse_Left") :
		Input.set_custom_mouse_cursor(load("res://Art/1.png"), Input.CURSOR_POINTING_HAND)
	if Input.is_action_just_released("Mouse_Left"):
		Input.set_custom_mouse_cursor(load("res://Art/0.png"), Input.CURSOR_POINTING_HAND)
	if get_child(-1) != timer and !landed:
		new_pig = get_child(-1)
		var pig_pos = new_pig.position 
		
		if pig_pos.distance_to(standing_spot) > speed:
			new_pig.position += pig_pos.direction_to(standing_spot)*speed
		else:
			new_pig.position = standing_spot
			GameVariables.pigeon_state[str(get_child(-1).get_name())] = "pigeon_idle" #State ændrer animation
			landed = true
			
			if str(new_pig.get_name()) not in GameVariables.tenants:
				get_child(-1).queue_free()
			timer.wait_time = randi_range(7,22)
			timer.start()

#Creates a new pigeon
func _on_timer_timeout():
	for child in get_children():
		if "newpig" in str(child.get_name()):
			return
	landed = false
	var pigeon = pigeon_scene.instantiate()
	
	#1/10 chance for different colored pigeons:
	if randi_range(1,10) == 2:
		pigeon.get_child(1).self_modulate = [Color8(225,0,randi_range(100,225)),Color8(225,randi_range(100,225),0),Color8(225,randi_range(100,225),randi_range(100,225))].pick_random() 
	
	var spawn_points = [Vector2(-85,randi_range(-50, 1220)), Vector2(randi_range(-20,2030),1220), Vector2(2030,randi_range(-50, 1220)), Vector2(randi_range(-20,2030),1220)]
	
	pigeon.position = spawn_points.pick_random()
	add_child(pigeon)
	pigeon.name = "newpig"
	
	if not rooms.is_empty():
		room_pos = rooms.pick_random()
		GameVariables.tenants[str(pigeon.get_name())] = room_pos
		rooms.erase(room_pos)
		full_rooms.append(room_pos)
		_start_request("/pigeon",HTTPClient.METHOD_POST, {"user": GameVariables.current_user_id, "pigeonhole": _gamepos_to_dbid(room_pos)})
		
	else:
		var x 
		var y 
		match spawn_points.find(pigeon.position) :
			-1:
				x = 2030
				y = 1220
			0:
				x = 2030
				y = randi_range(-50, 610)
				if pigeon.position.y < 610:
					y = randi_range(610, 1220)
			1: 
				x = randi_range(-20, 1000)
				if pigeon.position.x < 1000 :
					x = randi_range(1000, 2030)
				y = -50
			2: 
				x = -85
				y = randi_range(-50, 610)
				if pigeon.position.y < 610:
					y = randi_range(610, 1220)
			3:
				x = randi_range(-20, 1000)
				if pigeon.position.x < 1000 :
					x = randi_range(1000, 2030)
				y = -50 
		room_pos = Vector2(x,y)
	
	GameVariables.pigeon_state[str(pigeon.get_name())] = "pigeon_fly"
	standing_spot = room_pos
	
	get_child(-1).pigeon_clicked.connect(self._on_pigeon_clicked)
	
	if (room_pos.x - pigeon.position.x) > 0:
		pigeon.scale.x = -1
	
	
	

func _on_pigeon_clicked():
	sfx.stream = load("res://Art/SFX/Pigeon_Clicked.wav")
	sfx.play()
	if GameVariables.visiting == false and not GameVariables.shop_opened and not GameVariables.highscore_opened and not typeof(GameVariables.tenants[str(GameVariables.visited_pigeon)]) == TYPE_VECTOR2:
		clicked_pig = get_node(str(GameVariables.visited_pigeon))
		var clicked_pos = GameVariables.tenants[str(GameVariables.visited_pigeon)]["pos"] 
		
		camera.zoom = Vector2(2.5,2.5)
		camera.position = clicked_pos
		
		GameVariables.visiting = true
		back_button.visible = true
		accessory_button.visible = true
		minigames_button.visible = true
		stats_button.visible = true
		delete.visible = true
		shop.visible = false

func _on_back_button_pressed():
	sfx.stream = load("res://Art/SFX/clickSFX.wav")
	sfx.play()
	camera.zoom = Vector2(1,1)
	camera.position = Vector2(1000,600)
		
	GameVariables.visiting = false
	
	back_button.visible = false
	
	accessory_button.visible = false
	
	stats_button.visible = false
	stats_area.visible = false
	stats_text.visible = false
	
	minigames_button.visible = false
	
	accessory_area.visible = false
	item_list.visible = false
	delete.visible = false
	
	shop.visible = true

func _on_accessory_button_pressed():
	sfx.stream = load("res://Art/SFX/clickSFX.wav")
	sfx.play()
	accessory_area.visible = !accessory_area.visible
	item_list.visible = !item_list.visible
	
	stats_area.visible = false
	stats_text.visible = false
	
	item_list.clear()
	item_list.add_icon_item(load("res://Art/Cross.png"))
	for item in GameVariables.items:
		item_list.add_item(str(GameVariables.items[item]), load(GameVariables.store_items[int(item)][0]))

func _on_item_list_item_clicked(index, at_position, mouse_button_index):
	sfx.stream = load("res://Art/SFX/hat_onSFX.wav")
	sfx.play()
	if mouse_button_index == 1 :
		var accessory_node = clicked_pig.get_node("AnimatedSprite2D/Accessory")
		var previous_clothing
		
		#DEFO CLEAN CODE (NOT ANYMORRE!! - Natali)
		if index == 0:
			accessory_node.texture = load("res://Art/Items/placeholder_texture_2d.tres")
			if clicked_pig.get_name() in GameVariables.pigeon_clothes:
				previous_clothing = GameVariables.pigeon_clothes[clicked_pig.get_name()]
			#could also just remove entry?
			GameVariables.pigeon_clothes[str(clicked_pig.get_name())] = "res://Art/Items/placeholder_texture_2d.tres"
			if previous_clothing != null and previous_clothing != "res://Art/Items/placeholder_texture_2d.tres":
				for store_item in GameVariables.store_items:
					if GameVariables.store_items[store_item][0] == previous_clothing:
						_start_request("/equip_hat", HTTPClient.METHOD_PUT, {"pigeon": int(str(clicked_pig.get_name())), "hat": store_item})
						if !store_item in GameVariables.items :
							GameVariables.items[store_item] = 0
						GameVariables.items[store_item] += 1
						item_list.clear()
						item_list.add_icon_item(load("res://Art/Cross.png"))
						for item in GameVariables.items:
							item_list.add_item(str(GameVariables.items[item]), load(GameVariables.store_items[int(item)][0]))
						
			
		else:
			var item_index = GameVariables.items.keys()[index - 1]
			_start_request("/equip_hat", HTTPClient.METHOD_PUT, {"pigeon": int(str(clicked_pig.get_name())), "hat": item_index})
			accessory_node.texture = load(GameVariables.store_items[item_index][0])
			if GameVariables.pigeon_clothes.has(clicked_pig.get_name()) and GameVariables.pigeon_clothes[clicked_pig.get_name()] != "res://Art/Items/placeholder_texture_2d.tres":
				previous_clothing = GameVariables.pigeon_clothes[clicked_pig.get_name()]
			
			GameVariables.pigeon_clothes[str(clicked_pig.get_name())] = GameVariables.store_items[item_index][0]
			if GameVariables.pigeon_clothes.has(clicked_pig.get_name()) and GameVariables.pigeon_clothes[clicked_pig.get_name()] != "res://Art/Items/placeholder_texture_2d.tres":
				if item_index in GameVariables.items:
					if GameVariables.items[item_index] > 0 :
						GameVariables.items[item_index] -= 1
					if GameVariables.items[item_index] < 1 :
						GameVariables.items.erase(item_index)
				if previous_clothing != null:
					for store_item in GameVariables.store_items:
						if GameVariables.store_items[store_item][0] == previous_clothing:
							if !store_item in GameVariables.items :
								GameVariables.items[store_item] = 0
							GameVariables.items[store_item] += 1
				item_list.clear()
				item_list.add_icon_item(load("res://Art/Cross.png"))
				for item in GameVariables.items:
					item_list.add_item(str(GameVariables.items[item]), load(GameVariables.store_items[int(item)][0]))
					
		if GameVariables.pigeon_clothes.has(clicked_pig.get_name()) and GameVariables.pigeon_clothes[clicked_pig.get_name()] != "res://Art/Items/placeholder_texture_2d.tres":
			previous_clothing = GameVariables.pigeon_clothes[clicked_pig.get_name()]
		

	

func  _on_delete_pressed():
	sfx.stream = load("res://Art/SFX/Dead_Bird.wav")
	sfx.play()
	_start_request("/pigeon", HTTPClient.METHOD_DELETE, {"pigeon": int(str(clicked_pig.get_name()))})

#åbner minigames to choose from (kan man undgå en hel funktion til denne ene ting?)
#vi kan lave et signal til alle scene skifte knapper, sætte meta data også bare lave en match case hvis det vil være bedre :P
func _on_minigames_button_pressed():
	sfx.stream = load("res://Art/SFX/clickSFX.wav")
	sfx.play()
	shooter_button.visible = !shooter_button.visible
	clicker_button.visible = !clicker_button.visible

#To pigeon shooter!!
func _on_shooter_button_pressed():
	sfx.stream = load("res://Art/SFX/clickSFX.wav")
	sfx.play()
	get_tree().change_scene_to_file("res://pigeon_shooter.tscn")

#To Pigeon Clicker!!
func _on_clicker_button_pressed():
	sfx.stream = load("res://Art/SFX/clickSFX.wav")
	sfx.play()
	get_tree().change_scene_to_file("res://game.tscn")

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
	match (last_route):
		"/pigeon" when last_method == HTTPClient.METHOD_POST:
			_start_request("/pigeon", HTTPClient.METHOD_GET, {"pigeon": json[0][0]})
		"/pigeon" when last_method == HTTPClient.METHOD_GET:
			GameVariables.tenants.erase("newpig")
			GameVariables.tenants[str(json[0])] = {"pos": GameVariables.pigeonholes[int(json[2])], "state": "idle", "con": int(json[5]), "int": int(json[4]), "cha": int(json[3])}
			new_pig.name = str(json[0])
		"/pigeon" when last_method == HTTPClient.METHOD_DELETE :
			_start_request("/load_game", HTTPClient.METHOD_GET, {"user": GameVariables.current_user})
		"/load_game" :
			full_rooms.erase(GameVariables.tenants[str(clicked_pig.get_name())]["pos"])
			rooms.append(GameVariables.tenants[str(clicked_pig.get_name())]["pos"])
			clicked_pig.queue_free()
			GameVariables.tenants = {}
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
				GameVariables.tenants[str(pigeon[0])] = {"pos": pigeonholes[int(pigeon[1])], "state": "idle", "con": pigeon[4], "int": pigeon[3], "cha": pigeon[2], "hat": pigeon[5]} 
				GameVariables.pigeon_state[str(pigeon[0])] = "pigeon_idle"
			GameVariables.money = json["userData"][2]
			GameVariables.items = {}
			for hat in json['hats']:
				if hat[1] > 0:
					GameVariables.items[int(hat[0])] = hat[1]
			_on_back_button_pressed()
		_:
			var request = request_queue.pop_front()
			if request != null :
				_start_request(request["route"], request["method"], request["data"])
			
#Convert game pigeonhole position to database pigeonhole position
func _gamepos_to_dbid(pos):
	var translate_list = [Vector2(600,260),Vector2(1432,810),Vector2(1430,270)]
	return GameVariables.pigeonholes.keys()[translate_list.find(pos)]

func _dbpos_to_gamepos(pos):
	var translate_list = [Vector2(600,260),Vector2(1432,810),Vector2(1430,270)]
	return translate_list[pos]

func _on_stats_button_pressed():
	sfx.stream = load("res://Art/SFX/clickSFX.wav")
	sfx.play()
	stats_area.visible = !stats_area.visible
	stats_text.visible = !stats_text.visible
	
	accessory_area.visible = false
	item_list.visible = false
	
	stats_text.text = "[center] Stats:\n" + "CHA: " + str((GameVariables.tenants[GameVariables.visited_pigeon])["cha"]) + "\nCON: " + str((GameVariables.tenants[GameVariables.visited_pigeon])["con"])
