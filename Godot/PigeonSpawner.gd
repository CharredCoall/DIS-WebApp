extends Node2D

@onready var pigeon_scene = preload("res://pigeon.tscn")

@onready var timer = $Timer
@onready var camera = $Camera2D
@onready var back_button = $Camera2D/BackButton
@onready var accessory_button = $Camera2D/AccessoryButton
@onready var accessory_area = $Camera2D/AccessoryButton/AccessoriesArea
@onready var minigames_button = $Camera2D/MinigamesButton
@onready var shooter_button = $Camera2D/MinigamesButton/ShooterButton
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
var request_queue := []

# Called when the node enters the scene tree for the first time.
func _ready():
	#TEMPORARY LOGIN
	if GameVariables.current_user_id == -1:
		get_tree().change_scene_to_file("res://login.tscn")
		return
		#$TEMPORARY_LOGIN._start_request("/user",HTTPClient.METHOD_GET,{"username": "testUser", "pass": "testPassword"})
	else:
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
		if GameVariables.tenants[saved_pig]["hat"] != null:
			the_pig.get_node("AnimatedSprite2D/Accessory").texture = load(GameVariables.store_items[GameVariables.tenants[saved_pig]["hat"]][0]) 
		the_pig.pigeon_clicked.connect(self._on_pigeon_clicked)
		
		
		

func _process(_delta):
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
			print(get_children(true))
			timer.wait_time = randi_range(5,20) + 2
			timer.start()

#Creates a new pigeon
func _on_timer_timeout():
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
		if not GameVariables.room_occupancy.has(str(room_pos)):
			GameVariables.room_occupancy[str(room_pos)] = 1
		else:
			GameVariables.room_occupancy[str(room_pos)] += 1
	else:
		var x 
		var y 
		match spawn_points.find(pigeon.position) :
			-1:
				x = 2030
				y = 1220
				print("wrong?")
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
		print("Positions:")
		print(pigeon.position)
		print(str(x) + ", " + str(y))
		room_pos = Vector2(x,y)
	
	GameVariables.pigeon_state[str(pigeon.get_name())] = "pigeon_fly"
	
	standing_spot = room_pos
	
	get_child(-1).pigeon_clicked.connect(self._on_pigeon_clicked)
	
	if (room_pos.x - pigeon.position.x) > 0:
		pigeon.scale.x = -1
	
	#Remove room 
	if GameVariables.room_occupancy.get(str(room_pos)) == 1 and GameVariables.room_occupancy.has(str(room_pos)):
		_start_request("/pigeon",HTTPClient.METHOD_POST, {"user": GameVariables.current_user_id, "pigeonhole": _gamepos_to_dbid(room_pos)})
		rooms.erase(room_pos)
		full_rooms.append(room_pos)
	
	print('BIRB')
	print(GameVariables.tenants)
	print(GameVariables.room_occupancy)
	print(rooms)

func _on_pigeon_clicked():
	print(GameVariables.visiting)
	if GameVariables.visiting == false and not GameVariables.shop_opened and not typeof(GameVariables.tenants[str(GameVariables.visited_pigeon)]) == TYPE_VECTOR2:
		print(str(GameVariables.visited_pigeon))
		clicked_pig = get_node(str(GameVariables.visited_pigeon))
		var clicked_pos = GameVariables.tenants[str(GameVariables.visited_pigeon)]["pos"] 
		
		camera.zoom = Vector2(2.5,2.5)
		camera.position = clicked_pos
		
		GameVariables.visiting = true
		back_button.visible = true
		accessory_button.visible = true
		minigames_button.visible = true
		shop.visible = false

func _on_back_button_pressed():
	camera.zoom = Vector2(1,1)
	camera.position = Vector2(1000,600)
		
	GameVariables.visiting = false
	
	back_button.visible = false
	
	accessory_button.visible = false
	
	minigames_button.visble = false
	
	accessory_area.visible = false
	item_list.visible = false
	
	shop.visible = true

func _on_accessory_button_pressed():
	accessory_area.visible = !accessory_area.visible
	item_list.visible = !item_list.visible
	
	item_list.clear()
	item_list.add_icon_item(load("res://Art/Cross.png"))
	for item in GameVariables.items:
		item_list.add_item(str(GameVariables.items[item]), load(GameVariables.store_items[int(item)][0]))

func _on_item_list_item_clicked(index, at_position, mouse_button_index):
	if mouse_button_index == 1 :
		var accessory_node = clicked_pig.get_node("AnimatedSprite2D/Accessory")
		var previous_clothing
		
		#DEFO CLEAN CODE (NOT ANYMORRE!! - Natali)
		if index == 0:
			accessory_node.texture = load("res://Art/Items/placeholder_texture_2d.tres")
			if clicked_pig.get_name() in GameVariables.pigeon_clothes:
				previous_clothing = GameVariables.pigeon_clothes[clicked_pig.get_name()]
				print(previous_clothing)
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
			
#Convert game pigeonhole position to database pigeonhole position
func _gamepos_to_dbid(pos):
	var translate_list = [Vector2(600,260),Vector2(1432,810),Vector2(1430,270)]
	return GameVariables.pigeonholes.keys()[translate_list.find(pos)]
			
			
			
			

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

#åbner minigames to choose from (kan man undgå en hel funktion til denne ene ting?)
func _on_minigames_button_pressed():
	shooter_button.visible = !shooter_button.visible

#To pigeon shooter!!
func _on_shooter_button_pressed():
	get_tree().change_scene_to_file("res://pigeon_shooter.tscn")

