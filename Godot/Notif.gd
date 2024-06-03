extends Label

# Called when the node enters the scene tree for the first time.
func _ready():
	var new_sb = StyleBoxFlat.new()
	new_sb.bg_color = Color(1,0,0,0.2)
	new_sb.corner_radius_bottom_left = 20
	new_sb.corner_radius_top_left = 20
	new_sb.expand_margin_left = 40
	self.add_theme_stylebox_override("normal", new_sb)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _show_notif(text):
	self.text = text
	%GameManager/AnimationPlayer.play("Got_Notif")

