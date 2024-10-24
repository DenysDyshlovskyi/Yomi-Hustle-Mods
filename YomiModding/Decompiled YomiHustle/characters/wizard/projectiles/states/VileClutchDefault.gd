extends DefaultFireball

export  var screenshake_amount = 3
export  var screenshake_ticks = 15






func _ready():
	pass






func _frame_10():
	var camera = host.get_camera()
	if camera:
		camera.bump(Vector2.UP, screenshake_amount, screenshake_ticks / 60.0)
