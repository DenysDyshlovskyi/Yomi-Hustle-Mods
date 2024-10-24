extends RobotState








func _ready():
	pass






func _tick():
	if current_tick < 12 and current_tick > 4:
		host.set_vel(fixed.mul("5", str(host.get_facing_int())), "0")
