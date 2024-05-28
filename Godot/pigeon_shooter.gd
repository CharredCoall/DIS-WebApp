extends Node2D

@onready var cd_timer = $CountDownTimer
@onready var game_timer = $GameTimer
@onready var time_left_label = $TimeLeft
@onready var count_down_label = $CountDown
@onready var animation_player = $Background/AnimationPlayer
@onready var player = $Player

@onready var clothing_scene = preload("res://clothing.tscn")
@onready var projectile_scene = preload("res://projectile.tscn")

var count_down = 3
var speed = 800
var seconds = 0

func _ready():
	cd_timer.wait_time = 1

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_pressed("left") and player.position.x > 600:
		player.position.x -= speed * delta
	if Input.is_action_pressed("right") and player.position.x < 1300:
		player.position.x += speed * delta
	if Input.is_action_just_pressed("space"):
		var projectile = projectile_scene.instantiate()
		projectile.position = Vector2(player.position.x, player.position.y - 120)
		add_child(projectile)

func _on_timer_timeout():
	if count_down > 1:
		count_down -= 1
		
		count_down_label.text = "[center]Get ready!\n" + str(count_down)
	elif count_down in [1,0]:
		count_down_label.text = "[center]Get ready!\nGo!"
		
		if count_down == 0:
			count_down_label.queue_free()   #removed after use
			cd_timer.wait_time = 2
			game_timer.start()
			time_left_label.visible = true
		
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
		#play some sort of ending animation! (use animationplayer)
