extends Panel

@onready var sfx = get_parent().get_parent().get_node("SFXs")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _new_login():
	sfx.stream = load("res://Art/SFX/clickSFX.wav")
	sfx.play()
	%GameManager._start_request("/user", HTTPClient.METHOD_POST, {"username": $UsernameField.text, "pass": $PasswordField.text, "remember": $RememberField.button_pressed})
	
func _login():
	sfx.stream = load("res://Art/SFX/clickSFX.wav")
	sfx.play()
	%GameManager._start_request("/user", HTTPClient.METHOD_PUT, {"username": $UsernameField.text, "pass": $PasswordField.text, "remember": $RememberField.button_pressed})

