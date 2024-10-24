extends SuperMove

const MOVE_DISTANCE = 120
const NEUTRAL_STARTUP_LAG = 3
const LANDING_LAG = 2
const IASA = 20
const WHIFF_LANDING_LAG = 4
const WHIFF_IASA = 20
const BUFFER_ATTACK_GROUND_SNAP_DISTANCE = 4

var hitboxes = []

var dist = MOVE_DISTANCE

var attack = 0

var startup_lag = 0
var landing_lag = LANDING_LAG

var started_in_neutral = false

func _enter():
	dist = MOVE_DISTANCE
	hitboxes = []
	for child in get_children():
		if child is Hitbox:
			hitboxes.append(child)
			child.x = 0
			child.y = 0
	var move_dir
	attack = data.Attack.id
	if data:
		move_dir = xy_to_dir(data.Direction.x, data.Direction.y)

	else :
		move_dir = {"x": str(host.get_facing_int()), "y": "0"}
	var move_vec = fixed.vec_mul(move_dir.x, move_dir.y, "20")

	host.apply_force(move_vec.x, fixed.div(move_vec.y, "2"))
	host.quick_slash_move_dir_x = move_dir.x
	host.quick_slash_move_dir_y = move_dir.y































func _frame_0():
	started_in_neutral = host.combo_count <= 0
	host.set_grounded(false)
	var start_pos = host.get_pos().duplicate()
	host.quick_slash_start_pos_x = start_pos.x
	host.quick_slash_start_pos_y = start_pos.y
	if get_next_attack() and started_in_neutral:
		current_tick += 1





func _frame_4():
	if host.initiative:
		host.start_invulnerability()

func _frame_5():


	var move_dir_x = host.quick_slash_move_dir_x
	var move_dir_y = host.quick_slash_move_dir_y

	var move_vec = fixed.normalized_vec_times(move_dir_x, move_dir_y, str(MOVE_DISTANCE))
	
	host.move_directly(move_vec.x, move_vec.y)
	host.update_data()
	
	var start_pos_x = host.quick_slash_start_pos_x
	var start_pos_y = host.quick_slash_start_pos_y
	
	var end_pos = host.get_pos().duplicate()
	
	move_vec.x = end_pos.x - start_pos_x
	move_vec.y = end_pos.y - start_pos_y
	var pos = host.get_pos_visual()
	var particle_dir = Vector2(float(move_vec.x), float(move_vec.y)).normalized()
	host.spawn_particle_effect(preload("res://characters/stickman/QuickSlashEffect.tscn"), Vector2(start_pos_x, start_pos_y - 13), particle_dir)
	host.update_data()


func _frame_6():
	var start_pos_x = host.quick_slash_start_pos_x
	var start_pos_y = host.quick_slash_start_pos_y
	
	var end_pos = host.get_pos().duplicate()
	if start_pos_x != null and start_pos_y != null and end_pos.x != null and end_pos.y != null:
		for i in range(hitboxes.size()):
			var ratio = fixed.div(str(i), str(hitboxes.size()))
			hitboxes[i].x = fixed.round(fixed.sub(fixed.lerp_string(str(start_pos_x), str(end_pos.x), ratio), str(host.get_pos().x))) * host.get_facing_int()
			hitboxes[i].y = fixed.round(fixed.sub(fixed.lerp_string(str(start_pos_y), str(end_pos.y), ratio), str(host.get_pos().y))) - 16
	
	var move_dir_x = host.quick_slash_move_dir_x
	var move_dir_y = host.quick_slash_move_dir_y


	var next_attack = get_next_attack()

	if next_attack == null:
		host.reset_momentum()
		var move_vec = fixed.normalized_vec_times(move_dir_x, move_dir_y, "10")
		host.apply_force(move_dir_x, fixed.mul(move_dir_y, "1.0"))
		host.apply_force("0", "-1")









	else :
		if started_in_neutral:


				switch_to_followup()
				pass
	host.end_invulnerability()












func switch_to_followup():
	var vel = host.get_vel()
	host.set_vel(fixed.mul(vel.x, "0.25"), fixed.mul(vel.y, "0.5"))
	queue_state_change(get_next_attack())
	if host.get_pos().y > - BUFFER_ATTACK_GROUND_SNAP_DISTANCE:
		host.set_vel(vel.x, "0")
		host.move_directly(0, BUFFER_ATTACK_GROUND_SNAP_DISTANCE)
		host.set_grounded(true)
		host.set_vel(fixed.mul(vel.x, "0.35"), "0")

func get_next_attack():
	if not started_in_neutral:
		if not hit_anything:
			return null
	var grounded = host.get_pos().y > - BUFFER_ATTACK_GROUND_SNAP_DISTANCE
	match attack:
		0: return null
		1: return "GroundedPunchQS" if grounded else "AirUpwardPunchQS"
		2: return "GroundedSweepQS" if grounded else "AirAttackQS"
		3: return "NunChukHeavyQS" if grounded else "NunChukSpinQS"

func can_hit_cancel():
	return (host.combo_count > 1 or not host.opponent.is_grounded()) and attack == 0

func _got_parried():
	return 




func _on_hit_something(obj, hitbox):


	._on_hit_something(obj, hitbox)
	if get_next_attack() != null and not started_in_neutral:
		switch_to_followup()

func _tick():





	if get_next_attack() != null:
		if current_tick == 2:
			current_tick = 3
		
	if current_tick > 6:
		if host.is_grounded():
			if get_next_attack() == null:
				queue_state_change("Landing", landing_lag)
	host.apply_grav()

	host.apply_forces_no_limit()
