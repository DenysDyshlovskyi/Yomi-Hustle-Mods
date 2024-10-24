extends "res://projectile/DirProjectileDefault.gd"

onready var hitbox = $Hitbox





func _frame_0():
	._frame_0()
	var dir = data["dir"]
	hitbox.dir_x = fixed.mul(str(dir.x), str(host.get_facing_int()))
	hitbox.dir_y = str(dir.y)


func _ready():
	pass





