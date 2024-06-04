extends Sprite2D

@onready var munch = $"."
@onready var game_manager = %GameManager

var chance:int

var munch_dict:Dictionary = {
	"chewgum" : 1,
	"finger" : 2,
	"fish" : 2,
	"trash" : 3,
	"banana" : 3,
	"hotdog" : 4,
	"cake" : 7
} #Dictionary of the different pngs and how much their health multiplier is.

var munch_textures = []
var munch_texture_paths:Dictionary = {
	"chewgum" : {
		1 : "res://assets/Sprites/Munch/chewgum.png"
		},
	"finger" : {
		2 : "res://assets/Sprites/Munch/finger1.png",
		1 : "res://assets/Sprites/Munch/finger2.png"
		},
	"fish" : {
		2: "res://assets/Sprites/Munch/fish1.png", 
		1 : "res://assets/Sprites/Munch/fish2.png"
		},
	"trash" : {
		3 : "res://assets/Sprites/Munch/trash1.png", 
		2 : "res://assets/Sprites/Munch/trash2.png", 
		1 : "res://assets/Sprites/Munch/trash3.png"
		},
	"banana" : {
		3 : "res://assets/Sprites/Munch/banana1.png", 
		2 : "res://assets/Sprites/Munch/banana2.png", 
		1 : "res://assets/Sprites/Munch/banana3.png"
		},
	"hotdog" : {
		4 : "res://assets/Sprites/Munch/hotdog1.png", 
		3 : "res://assets/Sprites/Munch/hotdog2.png", 
		2 : "res://assets/Sprites/Munch/hotdog3.png", 
		1 : "res://assets/Sprites/Munch/hotdog4.png"
		},
	"cake" : {
		7 : "res://assets/Sprites/Munch/cake1.png", 
		6 : "res://assets/Sprites/Munch/cake2.png", 
		5 : "res://assets/Sprites/Munch/cake3.png", 
		4 : "res://assets/Sprites/Munch/cake4.png", 
		3 : "res://assets/Sprites/Munch/cake5.png", 
		2 : "res://assets/Sprites/Munch/cake6.png", 
		1 : "res://assets/Sprites/Munch/cake7.png"
		}
}

var current_munch_type: String
var current_munch_level: int
var max_health: int
var health: int
var health_threshold: int
var health_initialize: int

func _ready():
	pass

func initialize_chance(inichance):
	chance = inichance

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func take_damage(damage_amount: int):
	health -= damage_amount
	game_manager._change_health_label()
	if health <= 0:
		game_manager.add_point()
		_respawn()
	else:
		_update_texture_based_on_health()

func _respawn():
	health_initialize = 1
	_set_random_texture()

func _set_random_texture():
	var weighted_list = []
	for key in munch_dict.keys():
		var value = munch_dict[key]
		var weight = lerp(1, 100, float(chance) / 100) if value > 3 else lerp(100, 1, float(chance) / 100)
		for i in range(weight):
			weighted_list.append(key)
	current_munch_type = weighted_list[randi() % weighted_list.size()]
	_update_texture_based_on_health()

func _set_initial_health():
	var levels = munch_dict[current_munch_type]
	max_health = levels * 100
	health = max_health
	_update_health_threshold()

func _update_health_threshold():
	var levels = munch_dict[current_munch_type]
	if levels > 0:
		health_threshold = max_health / levels
	else:
		health_threshold = 1  # Ensure there's no division by zero

func _update_texture_based_on_health():
	if health_initialize == 1:
		health_initialize = 0
		_set_initial_health()  # Ensure health threshold is updated
	if health_threshold > 0:
		var texture_index = int(ceil(float(health) / float(health_threshold)))
		if texture_index < 1:
			texture_index = 1
		var texture_path = munch_texture_paths[current_munch_type][texture_index]
		munch.texture = load(texture_path)
	else:
		print("Error: health_threshold is zero or less, which should not happen.")
