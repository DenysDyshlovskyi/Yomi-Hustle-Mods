extends ObjectState

var hit_something = false

func _frame_0():
	if host.get_facing_int() == -1:
		host.sprite.flip_h = true

func _tick():
	if not hit_something : # Host.get_facing_int() gets either a -1 or 1 depending on character facing direction
		host.move_directly(6 * host.get_facing_int(),0)
		
	var pos = host.get_pos()
	if pos.x < -host.stage_width or pos.x > host.stage_width:
		hit_something = true
		host.disable()

func _on_hit_something(obj,hitbox):
	._on_hit_something(obj,hitbox)
	hit_something = true
	host.disable()
