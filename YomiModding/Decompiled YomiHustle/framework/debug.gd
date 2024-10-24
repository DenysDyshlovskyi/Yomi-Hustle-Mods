extends Node

var items = {
	
}

var times = {
	
}

var enabled = false
var unlock_everything = true
var text_enabled = false
var ai_enabled = false
var disable_parts = false
var regen_meter = false
var dbg_function

func dbg_enabled(id, value):
	items[id] = value

func dbg_disabled(_id, _value):
	pass

func _process(delta):
	if Input.is_action_just_pressed("debug_activate_ai"):
		ai_enabled = not ai_enabled



















func _enter_tree():
	if enabled and text_enabled:
		dbg_function = funcref(self, "dbg_enabled")
	else :
		dbg_function = funcref(self, "dbg_disabled")













func dbg(id, value):
	dbg_function.call_func(id, value)

func dbg_count(id, value, min_ = 1):
	if value >= min_:
		dbg(id, value)

func dbg_remove(id):
	items.erase(id)

func dbg_max(id, value):
	if not items.has(id) or items[id] < value:
		dbg(id, value)

func lines()->Array:
	var lines = []
	for id in items:
		lines.append(str(id) + ": " + str(items[id]))
	return lines
