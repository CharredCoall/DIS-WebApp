extends RigidBody2D

var line_end = Vector2(-132,347)
var landed = false
var gravity = 980   #this just matches godot's default gravity
var direction
var v0

# Called when the node enters the scene tree for the first time.
func _ready():
	get_child(randi_range(0,2)).visible = true
	
	var vx = float(randi_range(1000,1250))
	var angle = randf_range(30.,60.)
	
	v0 = calculate_v0(vx,deg_to_rad(angle))
	
	#play animation
	#randomize the vector
	
	apply_impulse(v0)

func _process(delta):
	if landed == true:  #when landed follow line
		freeze = true
		if has_node("CollisionShape2D"):
			$CollisionShape2D.queue_free()
			direction = (line_end - position).normalized()
		
		position += direction * 150 * delta
		
	if position <= line_end:
		queue_free()

func calculate_v0(vx,angle):    #velocity along x axis, angle in radians
	var v0_x = -vx * cos(angle) #negativ da til venstre
	var v0_y = vx * sin(angle)
	
	return Vector2(v0_x, -v0_y)  #y op er negativ, da godot op er negativ

func _on_body_entered(body):    #if hit by a projectile, add points
	if body.get_name() == "Projectile" or "StaticBody2D" in body.get_name():
		queue_free()
		body.speed = 500
		
		var sprite = body.get_node("PoopSprite")
		
		if body.get_meta("type") == "poop":
			GameVariables.current_score += 100
			body.get_node("CollisionShape2D").queue_free()
			sprite.texture = load("res://Art/Minigames/PigeonShooter/PoopSplatter.png")
		else:
			#egg can destroy more clothes in its path
			GameVariables.current_score += 100
			sprite.texture = load("res://Art/Minigames/PigeonShooter/EggSplatter.png")
			sprite.scale = Vector2(1.8,1.8)
