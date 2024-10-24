extends LineEdit
onready var button = $Button








func _ready():
	pass







func _on_Button_pressed():
	emit_signal("text_entered", text)
	pass
