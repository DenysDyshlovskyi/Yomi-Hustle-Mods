extends CharacterState


const STORE_MODIFIER = "0.90"



func _frame_1():

		var vel = host.get_vel()
		host.stored_momentum_x = fixed.add(host.stored_momentum_x, fixed.mul(fixed.abs(vel.x), STORE_MODIFIER))
		host.stored_momentum_y = fixed.add(host.stored_momentum_y, fixed.mul(fixed.abs(vel.y), STORE_MODIFIER))
		var speed = fixed.vec_len(host.stored_momentum_x, host.stored_momentum_y)
		var stored_speed = speed


		host.reset_momentum()
		host.momentum_stores = 1




		host.stored_speed_1 = stored_speed











func _tick():

		host.apply_fric()
		host.apply_grav()
		host.apply_forces()



func is_usable():


	return .is_usable() and (host.momentum_stores < 3 or host.infinite_resources)




