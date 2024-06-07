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
@onready var cd_timer = $StartTimer
@onready var cd_timer_label = $StartTimer/StartTimerLabel
@onready var hat_sprite = $Hat
@onready var sfx = $"../SFXs"
@onready var background_music = $"../BackgroundMusic"
var end_manager = null

#GameVariables.tenants[str(GameVariables.visited_pigeon.get_name())]["con"] #GameVariable for stats "con"/"cha"/"int"
var hat

@onready var score = 10
var characters = ["Q", "W", "E"]
var random_char:String
var positions = [Vector2(80,250), Vector2(1100,40), Vector2(1500,40), Vector2(1650,330), Vector2(1650,760), Vector2(88, 760), Vector2(88,488)]
var random_pos:Vector2
var con:int = GameVariables.tenants[str(GameVariables.visited_pigeon)]["con"] #GameVariable for stats "con"/"cha"/"int"
var chance:int = GameVariables.tenants[str(GameVariables.visited_pigeon)]["cha"] #GameVariable for stats "con"/"cha"/"int"
var intelligence:int = GameVariables.tenants[str(GameVariables.visited_pigeon)]["int"] #GameVariable for stats "con"/"cha"/"int"
var damage = 20+ceil(float(con**1.35/5))
var time:int = 10
var count_down = 3
var game_started = false

func _ready():
	if str(GameVariables.visited_pigeon) in GameVariables.pigeon_clothes:
		hat = GameVariables.pigeon_clothes[str(GameVariables.visited_pigeon)]
		hat_sprite.texture = load(hat)
	GameVariables.visiting = false
	game.visible = true
	set_end_scene_visibility(false)
	randomize()
	munch.initialize_chance(chance)
	munch._respawn()
	score_label.text = str(score) + " Points!"
	cd_timer.connect("timeout", Callable(self, "_on_CdTimer_timeout"))
	cd_timer.start(1)  # Start the countdown timer with 1 second intervals
	cd_timer_label.text = str(count_down)  # Initialize the countdown label

func _on_CdTimer_timeout():
	if count_down > 0:
		cd_timer_label.text = str(count_down)
		count_down -= 1
	elif count_down == 0:
		cd_timer_label.text = "Go!"
		count_down -= 1
	else:
		cd_timer_label.text = ""
		cd_timer.stop()
		start_game()

func start_game():
	game_timer.connect("timeout", Callable(self, "_on_Timer_timeout"))
	game_timer.start(time)
	change_label_randomly()
	game_started = true

func add_point():
	score += 9+munch.munch_dict[munch.current_munch_type]
	score_label.text = str(score) + " Points!"
	health_label.text = "100%"

func remove_point():
	if score > 2:
		if con < 21:
			score -= 3
		elif con > 20 and con < 51:
			score -= 4
		elif con > 50:
			score -= 5
		else:
			print("Illegal con value")
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
	if game_started and game.visible:
		timer_label.text = str(int(game_timer.time_left))
		if Input.is_action_just_pressed("Random_Q") and random_char == "Q":
			change_label_randomly()
			handle_player_input()
			goober.play("Munch")
			sfx.stream = load("res://Art/SFX/Chomp.wav")
			sfx.play()
		elif Input.is_action_just_pressed("Random_W") and random_char == "W":
			change_label_randomly()
			handle_player_input()
			goober.play("Munch")
			sfx.stream = load("res://Art/SFX/Chomp.wav")
			sfx.play()
		elif Input.is_action_just_pressed("Random_E") and random_char == "E":
			change_label_randomly()
			handle_player_input()
			goober.play("Munch")
			sfx.stream = load("res://Art/SFX/Chomp.wav")
			sfx.play()
		elif Input.is_action_just_pressed("Random_Q") and random_char != "Q" or Input.is_action_just_pressed("Random_W") and random_char != "W" or Input.is_action_just_pressed("Random_E") and random_char != "E":
			remove_point()
		else:
			pass

func _on_Timer_timeout():
	background_music.stream = load("res://Art/SFX/winSFX.mp3")
	background_music.play()
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
