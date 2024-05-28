extends StaticBody2D

var speed = 1100

# Called when the node enters the scene tree for the first time.
func _ready():
	#random chance for egg
	#depends on gamevariables.current_con
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	position.y -= speed * delta
	
	if position.y < 0:
		queue_free()
