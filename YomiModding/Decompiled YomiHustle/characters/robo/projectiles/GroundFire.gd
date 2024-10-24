extends BaseProjectile

export  var from_loic = false






func _ready():
	pass





func disable():
	.disable()
	var fighter = get_fighter()
	if fighter and fighter.flame_touching_opponent == obj_name:
		fighter.flame_touching_opponent = null
