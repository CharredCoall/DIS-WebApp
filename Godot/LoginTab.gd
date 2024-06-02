extends Panel


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _new_login():
	%GameManager._start_request("/user", HTTPClient.METHOD_POST, {"username": $UsernameField.text, "pass": $PasswordField.text})
	
func _login():
	%GameManager._start_request("/user", HTTPClient.METHOD_PUT, {"username": $UsernameField.text, "pass": $PasswordField.text})

