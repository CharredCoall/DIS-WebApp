extends TextureButton

var visibility = false
var http_ready = true
var last_route
var last_method 
var last_data
var request_queue = []
var game = "clicker"
var date_regex = RegEx.new()

# Called when the node enters the scene tree for the first time.
func _ready():
	$HTTPRequest.request_completed.connect(self._on_request_completed)
	
	$Label.text = game + " Highscores:"
	
	date_regex.compile(r"\w+, \d+ \w+ \d+")
	
	visibility = false
	for child in get_children():
		if child != $HTTPRequest:
			child.visible = visibility


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _pressed():
	if !visibility :
		GameVariables.highscore_opened = !GameVariables.highscore_opened
		_start_request("/score", HTTPClient.METHOD_GET, {})

func _exit_pressed():
	if visibility :
		visibility = false
		GameVariables.highscore_opened = !GameVariables.highscore_opened
		for child in get_children(true):
			if child != $HTTPRequest:
				child.visible = visibility
				
func _change_game():
	if game == "clicker":
		game = "shooter"
	else:
		game = "clicker"
	$Label.text = game + " Highscores:"
	_start_request("/score", HTTPClient.METHOD_GET, {})
	

func _start_request(route, method, data):
	if http_ready :
		last_route = route
		last_method = method
		var error
		if method == HTTPClient.METHOD_GET :
			var query_string = "?"
			for i in range(len(data)):
				if i != 0:
					query_string += "&"
				query_string += data.keys()[i] + "=" + data[data.keys()[i]] 
			error = $HTTPRequest.request(GameVariables.url + route + query_string, ["Content-Type: application/json", "Cookie: " + GameVariables.cookie], method)
		else:
			error = $HTTPRequest.request(GameVariables.url + route, ["Content-Type: application/json", "Cookie: " + GameVariables.cookie], method, JSON.stringify(data))
		if error != OK:
			push_error("An error occurred in the HTTP request.")
		http_ready = false
	
func _on_request_completed(result, response_code, headers, body):
	http_ready = true
	if response_code != 200:
		print(body.get_string_from_utf8())
		emit_signal("error",body.get_string_from_utf8())
		return
	var header_dict = {}
	var regex = RegEx.new()
	regex.compile(r"(\b[^:]*\b): ?(.*)")
	print(headers)
	for header in headers:
		result = regex.search(header)
		header_dict[result.get_string(1)] = result.get_string(2) 
	if 'Set-Cookie' in header_dict :
		GameVariables.cookie = header_dict['Set-Cookie']
	var body_string = body.get_string_from_utf8()
	var json = JSON.parse_string(body_string)
	if last_route == "/score":
		$ItemList.clear()
		for score in json :
			if score[1] == game :
				for i in range(3) :
					$ItemList.add_item(str(score[i]))
				$ItemList.add_item(date_regex.search(str(score[3])).get_string(0))
		visibility = true
		for child in get_children(true):
			if child != $HTTPRequest:
				child.visible = visibility
			
		
