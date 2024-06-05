extends Node2D

@onready var cd_timer = $CountDownTimer
@onready var game_timer = $GameTimer
@onready var time_left_label = $TimeLeft
@onready var score = $Score
@onready var count_down_label = $CountDown
@onready var animation_player = $Background/AnimationPlayer
@onready var cooldown_progress_bar = $ProgressBar
@onready var player = $Player

@onready var clothing_scene = preload("res://clothing.tscn")
@onready var projectile_scene = preload("res://projectile.tscn")

var count_down = 3
var speed = 800
var seconds = 0

var CON = (GameVariables.tenants[GameVariables.visited_pigeon])["con"]
var cooldown_time = 0.0
var cooldown_duration

func _ready():
	cooldown_duration = 1.0*(float(CON)/25.0)
	cooldown_progress_bar.max_value = cooldown_duration
	cd_timer.wait_time = 1

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_pressed("left") and player.position.x > 600:
		player.position.x -= speed * delta
	if Input.is_action_pressed("right") and player.position.x < 1300:
		player.position.x += speed * delta
	
	cooldown_time -= delta
	cooldown_progress_bar.value = cooldown_duration - cooldown_time
	
	#have a visual reload bar?
	if Input.is_action_just_pressed("space") and cooldown_time <= 0.:
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

func _on_game_timer_timeout():
	if seconds != 30:
		seconds += 1
		game_timer.start()
		time_left_label.text = "[center]" + str(int(time_left_label.text) - 1)
	else: 
		cd_timer.stop()
		#just pretty stuff
		count_down_label.add_theme_font_size_override("normal_font_size",160)
		count_down_label.add_theme_constant_override("shadow_offset_y",30)
		count_down_label.fit_content = true
		count_down_label.text = " Well done!\n Score: " + str(GameVariables.current_score) + "\n High score: X" + "\n Lvl up!"
		animation_player.play("game_done")
		#add to CON depending on INT

func _on_clothing_line_area_body_entered(body):  #checks if clothing lands on line
	body.landed = true

func _on_return_button_pressed():
	get_tree().change_scene_to_file("res://hotel.tscn")
