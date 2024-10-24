extends BeastState

const VEL_MUL = "0.5"

func _enter():
	var vel = host.get_vel()
	host.set_vel(fixed.mul(vel.x, VEL_MUL), fixed.mul(vel.y, VEL_MUL))


func _tick():
	if host.is_grounded():

		if current_tick > 8:
			return "Knockdown"





	var wall = host.touching_which_wall()
	if wall == fixed.sign(host.get_vel().x):
		queue_state_change("WallSlam", CharacterHurtState.BOUNCE.LEFT_WALL if wall == - 1 else CharacterHurtState.BOUNCE.RIGHT_WALL)
