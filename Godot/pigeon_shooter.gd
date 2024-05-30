extends Node2D

@onready var cd_timer = $CountDownTimer
@onready var game_timer = $GameTimer
@onready var time_left_label = $TimeLeft
@onready var score = $Score
@onready var count_down_label = $CountDown
@onready var animation_player = $Background/AnimationPlayer
@onready var player = $Player

@onready var clothing_scene = preload("res://clothing.tscn")
@onready var projectile_scene = preload("res://projectile.tscn")

var count_down = 3
var speed = 800
var seconds = 0

var http_ready = true
var url = "http://127.0.0.1:5000/"

func _ready():
	cd_timer.wait_time = 1
	
	$HTTPRequest.request_completed.connect(self._on_request_completed)
	_start_request()

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
	
	#måske skal der ikke opdateres hvert sekund?
	score.text = " " + str(GameVariables.current_score)

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
			score.visible = true
		
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

#DATABASE STUFF
func _start_request():  #henter pigeon 0's data
	if http_ready :
		var error = $HTTPRequest.request(url + "/pigeon", ["Content-Type: application/json"], HTTPClient.METHOD_GET, JSON.stringify({'pigeon': 0}))  #ændr f.eks. 'pigeon' i dict til GameVariables.visited_pigeon
		if error != OK:
			push_error("An error occurred in the HTTP request.")
		http_ready = false
	
func _on_request_completed(result, response_code, headers, body):
	http_ready = true
	var body_string = body.get_string_from_utf8()
	var json = JSON.parse_string(body_string)
	
	#Sætter current pigeons stats til game variables
	GameVariables.current_chance = json[4]
	GameVariables.current_int = json[5]
	GameVariables.current_con = json[6]
	print(json)
	print("Chance score: " + str(GameVariables.current_chance))
