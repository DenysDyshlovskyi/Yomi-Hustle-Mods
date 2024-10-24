extends ObjectState


func create_particle():
	spawn_particle_relative(preload("res://characters/stickman/projectiles/SummonParticle.tscn"))

func _frame_1():
	create_particle()

func _tick():
	host.apply_grav()
	host.apply_fric()
	host.apply_forces()
	if host.is_grounded():
		return "Slide"
	host.set_facing(host.get_facing_int())










