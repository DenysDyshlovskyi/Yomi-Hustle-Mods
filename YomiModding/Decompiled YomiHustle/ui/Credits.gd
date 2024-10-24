extends PanelContainer








func _ready():
	pass







func _on_Button_pressed():
	Global.reload()


func _on_TextureButton_pressed():
	OS.shell_open("https://godotengine.org/")
	pass
