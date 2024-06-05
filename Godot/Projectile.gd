extends StaticBody2D

var speed = 1100
var CHA = (GameVariables.tenants[GameVariables.visited_pigeon])["cha"]

# Called when the node enters the scene tree for the first time.
func _ready():
	if randi_range(0,100) <= CHA:  #so at 100 CHA there's 100% chance for egg
		$PoopSprite.texture = load("res://Art/Minigames/PigeonShooter/Egg.png")
		$PoopSprite.scale = Vector2(1.8,1.8)
		$CollisionShape2D.shape.radius = 100.
		set_meta("type","egg")
	#depends on gamevariables.current_con

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	position.y -= speed * delta
	
	if position.y < 0:
		queue_free()
