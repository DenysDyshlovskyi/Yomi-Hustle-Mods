extends WizardState

onready var hitbox = $Hitbox

const MAX_DISTANCE = "120"
const MIN_DISTANCE = "30"

const MAX_EXTRA_STARTUP = 0

var hitbox_x

var startup_lag = 0

func _enter():
	startup_lag = 0

	startup_lag = fixed.round(fixed.mul(fixed.div(str(data["x"]), "100"), str(MAX_EXTRA_STARTUP)))












func _tick():
	if current_tick == 2:
		if startup_lag > 0:
			startup_lag -= 1
			current_tick = 1
	if current_tick == 5:
		host.update_data()
		var dir = xy_to_dir(data["x"], 0, "1.0")
		dir.x = fixed.add(dir.x, "1.0")
		dir.x = fixed.div(dir.x, "2.0")
	
		hitbox_x = fixed.round(fixed.add(fixed.mul(dir.x, fixed.sub(MAX_DISTANCE, MIN_DISTANCE)), MIN_DISTANCE)) * host.get_facing_int()
		hitbox.x = Utils.int_abs(hitbox_x)
	if current_tick == 5:
		spawn_particle_relative(particle_scene, Vector2(hitbox_x, hitbox.y))

func _exit():
	startup_lag = 0
