extends Node2D

@onready var pigeon_scene = preload("res://pigeon.tscn")

@onready var timer = $Timer
@onready var camera = $Camera2D
@onready var back_button = $Camera2D/BackButton
@onready var accessory_button = $Camera2D/AccessoryButton
@onready var accessory_area = $Camera2D/AccessoryButton/AccessoriesArea
@onready var shop = $Shop

@onready var item_list = $Camera2D/AccessoryButton/ItemList

@export var speed = 5

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

# Called when the node enters the scene tree for the first time.
func _ready():
	#TEMPORARY LOGIN
	if GameVariables.current_user_id == -1:
		$TEMPORARY_LOGIN._start_request("/user",HTTPClient.METHOD_GET,{"username": "testUser", "pass": "testPassword"})
	
	
	timer.wait_time = randi_range(5,20)

func _place_pigeons():
	for item in GameVariables.items:
		item_list.add_icon_item(load(item))
	
	for saved_pig in GameVariables.tenants:
		var the_pig = pigeon_scene.instantiate()
		the_pig.position = GameVariables.tenants[saved_pig]["pos"]
		standing_spot = GameVariables.tenants[saved_pig]["pos"]
		full_rooms.append(GameVariables.tenants[saved_pig]["pos"])
		rooms.erase(GameVariables.tenants[saved_pig]["pos"])
		add_child(the_pig)
		move_child(the_pig,-2)
		the_pig.name = saved_pig
		the_pig.pigeon_clicked.connect(self._on_pigeon_clicked)
		
		
		

func _process(_delta):
	if get_child(-1) != timer and landed == false:
		new_pig = get_child(-1)
		var pig_pos = new_pig.position 
		
		if pig_pos.distance_to(standing_spot) > speed:
			new_pig.position += pig_pos.direction_to(standing_spot)*speed
		else:
			new_pig.position = standing_spot
			GameVariables.pigeon_state[str(get_child(-1).get_name())] = "pigeon_idle" #State ændrer animation
			landed = true
			
			if str(new_pig.get_name()) not in GameVariables.tenants && str(new_pig.get_name()) != "newpig":
				get_child(-1).queue_free()
	
	if GameVariables.room_occupancy.get(str(room_pos)) == 1 and GameVariables.room_occupancy.has(str(room_pos)):
		_start_request("/pigeon",HTTPClient.METHOD_POST, {"user": GameVariables.current_user_id, "pigeonhole": _gamepos_to_dbpos(room_pos)})
		rooms.erase(room_pos)
		full_rooms.append(room_pos)

func _on_timer_timeout():
	landed = false
	timer.wait_time = randi_range(5,20) + 2
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
		if not GameVariables.room_occupancy.has(str(room_pos)):
			GameVariables.room_occupancy[str(room_pos)] = 1
		else:
			GameVariables.room_occupancy[str(room_pos)] += 1
		GameVariables.pigeon_state[str(pigeon.get_name())] = "pigeon_fly"
	else:
		room_pos = Vector2(0,0) #CHANGE!
		GameVariables.pigeon_state[str(pigeon.get_name())] = "pigeon_fly"
	
	standing_spot = room_pos
	
	if GameVariables.room_occupancy.has(str(room_pos)) and GameVariables.room_occupancy[str(room_pos)] == 1:
		standing_spot.x -= 25
	else:
		standing_spot.x += 25
	
	get_child(-1).pigeon_clicked.connect(self._on_pigeon_clicked)
	
	if (room_pos.x - pigeon.position.x) > 0:
		pigeon.scale.x = -1
	
	#maybe move full rooms sorting down here?
	
	print('BIRB')
	print(GameVariables.tenants)
	print(GameVariables.room_occupancy)
	print(rooms)

func _on_pigeon_clicked():
	print(GameVariables.visiting)
	if GameVariables.visiting == false and not GameVariables.shop_opened:
		clicked_pig = get_node(str(GameVariables.visited_pigeon))
		var clicked_pos = GameVariables.tenants[str(GameVariables.visited_pigeon)]["pos"] #ændr
		
		camera.zoom = Vector2(2.5,2.5)
		camera.position = clicked_pos
		
		GameVariables.visiting = true
		back_button.visible = true
		accessory_button.visible = true
		shop.visible = false
		

func _on_back_button_pressed():
	camera.zoom = Vector2(1,1)
	camera.position = Vector2(1000,600)
		
	GameVariables.visiting = false
	
	back_button.visible = false
	
	accessory_button.visible = false
	
	accessory_area.visible = false
	item_list.visible = false
	
	shop.visible = true

func _on_accessory_button_pressed():
	accessory_area.visible = !accessory_area.visible
	item_list.visible = !item_list.visible
	
	if len(GameVariables.items) > item_list.item_count - 1:
		var diff = abs(len(GameVariables.items) - (item_list.item_count - 1))
		for n in range(-diff,0):
			print(n)
			item_list.add_icon_item(load(GameVariables.items[n]))

func _on_item_list_item_clicked(index, at_position, mouse_button_index):
	var accessory_node = clicked_pig.get_node("AnimatedSprite2D/Accessory")
	var previous_clothing
	
	#DEFO CLEAN CODE
	if index == 0:
		accessory_node.texture = load("res://Art/Items/placeholder_texture_2d.tres")
		previous_clothing = GameVariables.pigeon_clothes[clicked_pig.get_name()]
		#could also just remove entry?
		GameVariables.pigeon_clothes[str(clicked_pig.get_name())] = "res://Art/Items/placeholder_texture_2d.tres"
		
		if previous_clothing != null and previous_clothing != "res://Art/Items/placeholder_texture_2d.tres":
			GameVariables.items.append(previous_clothing)
			item_list.add_icon_item(load(previous_clothing))
		
	else:
		accessory_node.texture = load(GameVariables.items[index - 1])
		if GameVariables.pigeon_clothes.has(clicked_pig.get_name()) and GameVariables.pigeon_clothes[clicked_pig.get_name()] != "res://Art/Items/placeholder_texture_2d.tres":
			previous_clothing = GameVariables.pigeon_clothes[clicked_pig.get_name()]
		
		GameVariables.pigeon_clothes[str(clicked_pig.get_name())] = GameVariables.items[index - 1]
		if GameVariables.pigeon_clothes.has(clicked_pig.get_name()) and GameVariables.pigeon_clothes[clicked_pig.get_name()] != "res://Art/Items/placeholder_texture_2d.tres":
			GameVariables.items.remove_at(index - 1)
			item_list.remove_item(index)
			if previous_clothing != null:
				GameVariables.items.append(previous_clothing)
				item_list.add_icon_item(load(previous_clothing))
	
	print(GameVariables.pigeon_clothes)
	
	
	
	



func _start_request(route, method, data):
	if http_ready :
		last_route = route
		last_method = method
		last_data = data
		$HTTPRequest.request_completed.connect(self._on_request_completed)
		var error = $HTTPRequest.request(GameVariables.url + route, ["Content-Type: application/json","Cookie: " + GameVariables.cookie], method, JSON.stringify(data))
		if error != OK:
			push_error("An error occurred in the HTTP request.")
		http_ready = false



func _on_request_completed(result, response_code, headers, body):
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
	http_ready = true
	var body_string = body.get_string_from_utf8()
	var json = JSON.parse_string(body_string)
	match (last_route):
		"/pigeon" when last_method == HTTPClient.METHOD_POST:
			_start_request("/pigeon", HTTPClient.METHOD_GET, {"pigeon": json[0][0]})
		"/pigeon" when last_method == HTTPClient.METHOD_GET:
			GameVariables.tenants.erase("newpig")
			GameVariables.tenants[str(json[0])] = {"pos": GameVariables.pigeonholes[json[2]], "state": "idle", "con": json[5], "int": json[4], "cha": json[3]}
			new_pig.name = str(json[0])
			
			
			
			
func _gamepos_to_dbpos(pos):
	var translate_list = [Vector2(600,260),Vector2(1432,810),Vector2(1430,270)]
	return translate_list.find(pos)
			
			
			
			
			
