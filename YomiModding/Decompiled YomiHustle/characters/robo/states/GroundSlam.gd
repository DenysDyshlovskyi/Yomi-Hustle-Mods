extends ThrowState

const WALK_BACK_SPEED = "-4.0"
const WALK_FORWARD_SPEED = "6.0"

const SINGLE_HIT_WAIT_TICKS = 2
const SINGLE_HIT_START_TICK = 31
const SINGLE_HIT_WAIT_TICK = 32

onready var no_combo_hitbox = $NoComboHitbox
onready var hitbox = $Hitbox

export  var single_hit = false

var is_in_combo = false

var single_hit_wait_ticks = 0
























func walk_back():
	host.apply_force_relative(WALK_BACK_SPEED, "0")

func walk_forward():
	host.apply_force_relative(WALK_FORWARD_SPEED, "0")


func _frame_0():

	host.opponent.z_index = - 1


	walk_back()
	is_in_combo = host.combo_count != 0
	if single_hit:
		current_tick = SINGLE_HIT_START_TICK

func _frame_7():
	host.move_directly_relative( - 16, 0)

func _frame_16():
	walk_forward()

func _frame_21():
	ground_slam()
	host.move_directly_relative(16, 0)

func _frame_28():
	walk_back()
	host.move_directly_relative( - 16, 0)


func _frame_32():
	if single_hit:
		single_hit_wait_ticks = SINGLE_HIT_WAIT_TICKS
		host.turn_around()
	if _previous_state().get("reversing_command_grab"):
		host.set_facing(host.get_facing_int() * - 1)
func _frame_36():

	walk_forward()

func _frame_39():

	host.move_directly_relative(16, 0)
	
func _frame_40():
	ground_slam()
	_release()

func _frame_44():
	walk_back()

func ground_slam():
	var pos = particle_position
	pos.x *= host.get_facing_int()
	spawn_particle_relative(particle_scene, pos)
	if not is_in_combo:
		no_combo_hitbox.hit(host.opponent)
	else :
		hitbox.hit(host.opponent)


	no_combo_hitbox.deactivate()
	hitbox.deactivate()
	var camera = host.get_camera()
	if camera:
		camera.bump(Vector2.UP, 20, 20 / 60.0)

func _tick():
	if single_hit_wait_ticks > 0:
		single_hit_wait_ticks -= 1
		current_tick = SINGLE_HIT_WAIT_TICK


func _exit():
	is_in_combo = false
