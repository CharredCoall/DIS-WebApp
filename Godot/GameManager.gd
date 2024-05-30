extends Node

var current_user := ""
var current_user_id := -1 
var url = "http://127.0.0.1:5000/"
var http_ready := true
var cookie := ""

# Called when the node enters the scene tree for the first time.
func _ready():
	$Label.text = current_user + " " + str(current_user_id)
	$HTTPRequest.request_completed.connect(self._on_request_completed)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _open_logintab():
	$LoginTab/LoginAnimation.play("ZoomLoginTab")


func _close_logintab():
	$LoginTab/LoginAnimation.play_backwards("ZoomLoginTab")


func _start_request(route, method, data):
	if http_ready :
		var error = $HTTPRequest.request(url + route, ["Content-Type: application/json","Cookie: " + cookie], method, JSON.stringify(data))
		if error != OK:
			push_error("An error occurred in the HTTP request.")
		http_ready = false
	
func _on_request_completed(result, response_code, headers, body):
	var header_dict = {}
	var regex = RegEx.new()
	regex.compile(r"(\b[^:]*\b): (.*)")
	for header in headers:
		result = regex.search(header)
		header_dict[result.get_string(1)] = result.get_string(2) 
	if 'Set-Cookie' in header_dict :
		cookie = header_dict['Set-Cookie']
	http_ready = true
	var body_string = body.get_string_from_utf8()
	var json = JSON.parse_string(body_string)
	print(json)
	if typeof(json) == TYPE_BOOL :
		if json :
			_start_request("/load_game",HTTPClient.METHOD_GET, {"user": $LoginTab/UsernameField.text})
	elif typeof(json) == TYPE_DICTIONARY :
		current_user = json["userData"][1]
		current_user_id = json["userData"][0]
		$Label.text = current_user + " " + str(current_user_id)
	elif response_code == 200 :
			_start_request("/load_game",HTTPClient.METHOD_GET, {"user": $LoginTab/UsernameField.text})
		
	
			
			
			
			
			
			
			
			
			
			
			 
