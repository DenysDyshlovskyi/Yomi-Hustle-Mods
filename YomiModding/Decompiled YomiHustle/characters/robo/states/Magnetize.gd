extends RobotState

func _frame_0():

	host.start_magnetizing()






func _tick():
	if current_tick == 7 and host.combo_count > 0:
		enable_interrupt()

func is_usable():
	return .is_usable() and (host.magnet_ticks_left <= 0 and host.grenade_object != null)
