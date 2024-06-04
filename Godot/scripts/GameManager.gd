extends Node

@onready var goober = $Node2D/AnimatedSprite2D
@onready var score_label = $ScoreLabel
@onready var health_label = $Health_Label
@onready var munch = $Munch
@onready var instruction_label = $InstructionLabel
@onready var game_timer = $GameTimer
@onready var timer_label = $GameTimer/TimerLabel
@onready var game = $".."
@onready var end_screen = $EndScreen
var end_manager = null

var score = 10
var characters = ["Q", "W", "E"]
var random_char:String
var positions = [Vector2(80,250), Vector2(1100,40), Vector2(1500,40), Vector2(1650,330), Vector2(1650,760), Vector2(88, 760), Vector2(88,488)]
var random_pos:Vector2
var con:int = 89
var chance:int = 21
var intelligence:int = 10
var damage = 20+ceil(float(con**1.25/5))
var time:int = 60

func _ready():
	game.visible = true
	set_end_scene_visibility(false)
	randomize()
	munch.initialize_chance(chance)
	munch._respawn()
	score_label.text = str(score) + " Points!"
	game_timer.connect("timeout", Callable(self, "_on_Timer_timeout"))
	game_timer.start(time)
	change_label_randomly()

func add_point():
	score += 9+munch.munch_dict[munch.current_munch_type]
	score_label.text = str(score) + " Points!"
	health_label.text = "100%"

func remove_point():
	if score > 2:
		score -= 3
	score_label.text = str(score) + " Points!"

func _on_animated_sprite_2d_animation_finished():
	goober.play("Idle")

func _change_health_label():
	var procent_health:float = ceil(100.0 * float(munch.health) / float(munch.max_health))
	health_label.text = str(procent_health) + "%"

func change_label_randomly():
	random_char = characters[randi() % characters.size()]
	random_pos = positions[randi() % positions.size()]
	instruction_label.text = random_char
	instruction_label.position = random_pos

func handle_player_input():
	munch.take_damage(damage)

func _process(_delta):
	timer_label.text = str(int(game_timer.time_left))
	if Input.is_action_just_pressed("Random_Q") and random_char == "Q":
		change_label_randomly()
		handle_player_input()
		goober.play("Munch")
	elif Input.is_action_just_pressed("Random_W") and random_char == "W":
		change_label_randomly()
		handle_player_input()
		goober.play("Munch")
	elif Input.is_action_just_pressed("Random_E") and random_char == "E":
		change_label_randomly()
		handle_player_input()
		goober.play("Munch")
	elif Input.is_action_just_pressed("Random_Q") and random_char != "Q" or Input.is_action_just_pressed("Random_W") and random_char != "W" or Input.is_action_just_pressed("Random_E") and random_char != "E":
		remove_point()
	else:
		pass

func _on_Timer_timeout():
	change_scene()

func change_scene():
	game.visible = false
	set_end_scene_visibility(true)
	call_deferred("_initialize_end_manager")

func _initialize_end_manager():
	end_manager = end_screen.get_node("EndManager")
	if end_manager:
		end_manager.set_score(score)
		end_manager.level_up(con, intelligence)
		end_manager.display_stuff(con)
	else:
		print("Error: EndManager node not found")

func set_end_scene_visibility(visible: bool):
	end_screen.visible = visible
	set_visibility_recursive(end_screen, visible)

func set_visibility_recursive(node: Node, visible: bool):
	if node is CanvasItem:
		node.visible = visible
	for child in node.get_children():
		set_visibility_recursive(child, visible)
