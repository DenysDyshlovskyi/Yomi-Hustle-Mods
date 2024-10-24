extends Camera2D

class_name GoodCamera

const MAX_SHAKE_AMOUNT = 50
const SCREENSHAKE_MODIFIER = 1.5
const SCREENSHAKE_TIME_MODIFIER = 1.5

export  var default_screenshake_amount = 2.0
export  var default_screenshake_time = 0.1




var shake_amount = 0
var rng = BetterRng.new()


var offsets = []
var tweens = []

var current_speed = 0.0
var current_direction = Vector2()
var last_pos = Vector2()

var focused_object = null

class Offset extends Reference:
	var rng: BetterRng
	var dir = Vector2()
	var amount: float = 0
	var random = false

	func get_value():
		if not random:
			return dir * amount
		else :
			return amount * rng.random_vec()
	
func _ready():
	rng.randomize()

func bump_at_location(dir, location = global_position, amount: = default_screenshake_amount, time: = default_screenshake_time, falloff = 1400, power = 4):


	bump(dir, amount - (1 - pow(1 - clamp((location.distance_to(global_position) / falloff), 0, 1), power)) * amount, time)

func reset_shake():
	offsets = []
	for tween in tweens:
		tween.reset()
	tweens = []
	
func bump(dir = Vector2(), amount = default_screenshake_amount, time = default_screenshake_time):
	if amount > MAX_SHAKE_AMOUNT:
		amount = MAX_SHAKE_AMOUNT
	amount = float(amount)
	time = float(time)
	amount *= SCREENSHAKE_MODIFIER
	time *= SCREENSHAKE_TIME_MODIFIER


	var shake_tween = create_tween()
	shake_tween.set_parallel(false)
	shake_tween.set_trans(Tween.TRANS_EXPO)
	shake_tween.set_ease(Tween.EASE_OUT)
	var offs = Offset.new()
	offs.dir = dir
	offs.rng = rng
	
	
	if dir == Vector2():
		offs.random = true
	
	offsets.append(offs)
	
	shake_tween.tween_property(offs, "amount", amount, 0.0025)
	if not offs.random:
		shake_tween.set_trans(Tween.TRANS_ELASTIC)
	else :
		shake_tween.set_trans(Tween.TRANS_CIRC)
	shake_tween.set_ease(Tween.EASE_OUT)
	


	shake_tween.tween_property(offs, "amount", 0.0, time)

	yield (shake_tween, "finished")
	if not is_instance_valid(self):
		return 
	shake_tween.kill()

	offsets.erase(offs)



func tick():
	current_speed = lerp(current_speed, position.distance_to(last_pos), 0.85)
	current_direction = lerp(current_direction, (position - last_pos).normalized(), 0.5)
	last_pos = position

	offset = Vector2()

	var offset_values = []
	for offs in offsets:
		var value = offs.get_value()
		offset += value
		offset_values.append(value)





