extends "res://characters/wizard/projectiles/orb/states/Default.gd"

const LOCKED_DAMAGE = 85
const UNLOCKED_DAMAGE = 60

onready var hitbox_3 = $Hitbox3
onready var hitbox_2 = $Hitbox2
onready var hitbox = $Hitbox

func _enter():



	for h in [hitbox, hitbox_2]:
		h.scale_combo = not host.locked


func _tick():
	._tick()
	if not host.locked:
		hitbox.scale_combo = true
		hitbox_2.scale_combo = true
