extends ThrowState








func _ready():
	pass






func _enter():
	host.grab_camera_focus()
	host.opponent.z_index = - 2

func _exit():
	host.release_camera_focus()

func _tick():

	host.apply_grav_custom("0.66", "20")
	if current_tick % 12 == 0:
		host.play_sound("ArmSpin")
	if host.is_grounded():
		host.throw_pos_x = release_throw_pos_x
		host.throw_pos_y = release_throw_pos_y
		var pos = host.get_global_throw_pos()
		host.opponent.set_pos(pos.x, pos.y)
		host.opponent.update_facing()
		return "KillProcessLanding"
