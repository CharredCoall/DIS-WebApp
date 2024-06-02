extends Node2D

@onready var sprite_animator = $AnimatedSprite2D
@onready var animation_player = $AnimationPlayer
@onready var button = $Button
@onready var timer = $Timer

signal pigeon_clicked

func _ready():
	timer.wait_time = randi_range(5,20)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if GameVariables.pigeon_state.has(get_name()):
		sprite_animator.play(GameVariables.pigeon_state[get_name()])
	
	if sprite_animator.animation == "pigeon_idle" and timer.is_stopped():
		timer.start()
		
	#make pigeons h flip at random times

func _on_button_pressed():
	if ! "newpig" in button.get_parent().get_name() and str(get_name()) not in GameVariables.pigeon_state or GameVariables.pigeon_state[str(get_name())] != "pigeon_fly": 
		print("Clicky click!")
		
		GameVariables.pigeon_state[str(get_name())] = "pigeon_touch"
		
		sprite_animator.play("pigeon_touch")
	
		GameVariables.visited_pigeon = button.get_parent().get_name()
		
		emit_signal("pigeon_clicked")

func _on_animation_finished():
	#sprite animation finished
	GameVariables.pigeon_state[str(get_name())] = "pigeon_idle"

func _on_idle_anim_timer_timeout():
	#When the the idle animation has been run for random number of seconds
	GameVariables.pigeon_state[str(get_name())] = "pigeon_walk"
	animation_player.play("pigeon_move")

func _on_animation_player_animation_finished(anim_name):
	#animation player finished
	GameVariables.pigeon_state[str(get_name())] = "pigeon_idle"
	timer.wait_time = randi_range(5,20)
