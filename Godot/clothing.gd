extends RigidBody2D

var landing_pos = Vector2(400, 450)
var gravity = 980   #this just matches godot's default gravity
var v0

# Called when the node enters the scene tree for the first time.
func _ready():
	get_child(randi_range(0,2)).visible = true
	
	var rnd_time = randf_range(1.5,2.5)
	
	v0 = calculate_v0(rnd_time)
	
	#play animation
	#randomize the vector
	#if clothing collides with hanging line (metadata?) then make it run along the line and disappear
	
	apply_impulse(v0)

func _process(_delta):
	if position.distance_to(landing_pos) < 10:
		print("HERE")
		visible = false

func calculate_v0(dt):    #time it takes to travel
	var x_distance = landing_pos.x - global_position.x
	var y_distance = landing_pos.y - global_position.y
	
	var v0_x = x_distance / dt
	var v0_y = (y_distance + 0.5 * gravity * dt ** 2) / dt
	
	var dist_max = (v0_x**2+v0_y**2)/abs(gravity)
	
	return Vector2(v0_x, -v0_y)  #y op er negativ, da godot op er negativ

func _on_body_entered(body):
	if body.get_name() == "Projectile" or "StaticBody2D" in body.get_name():
		queue_free()
		GameVariables.current_score += 10
		body.speed = 500
		
		body.get_node("CollisionShape2D").queue_free()
		body.get_node("PoopSprite").texture = load("res://Art/Minigames/PigeonShooter/PoopSplatter.png")
		
		print(body.speed)

