extends Label








func _ready():
	if not Debug.text_enabled:
		return 
	pass


func _process(delta):
	if Debug.enabled:

		text = ""
		for line in Debug.lines():
			text = text + line + "\n"
