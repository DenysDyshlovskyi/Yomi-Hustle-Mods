extends BeastState

export  var grounded = false

func _enter():
	land_cancel_state = "Landing"

func _tick():
	if (current_tick < (2 if not grounded else 5)) and host.combo_count <= 0:
		land_cancel_state = "Landing"
	else :
		land_cancel_state = "ShredLandCancel"











func _frame_4():
	if grounded:
		host.start_projectile_invulnerability()















