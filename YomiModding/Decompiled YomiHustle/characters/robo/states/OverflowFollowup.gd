extends ThrowState








func _ready():
	pass

func _frame_0():
	host.flying_dir = null
	host.stop_fly_fx()
	if host.air_movements_left < host.num_air_movements:
		host.air_movements_left += 1




func _frame_5():
	host.play_sound("Charge")
	host.play_sound("Charge2")

func _frame_31():
	host.play_sound("OverflowBeep")
	host.play_sound("HitBass")

func _tick():
	if current_tick in [15, 21]:
		host.play_sound("ArmSpin2")
