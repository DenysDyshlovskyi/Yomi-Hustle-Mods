extends WizardState


const PROJECTILE_X = 10
const PROJECTILE_Y = - 16

func _frame_7():


	var dir = xy_to_dir(data["x"], data["y"])
	var obj = host.spawn_object(preload("res://characters/wizard/projectiles/MagicMissile.tscn"), PROJECTILE_X, PROJECTILE_Y, true, {"dir": dir})
