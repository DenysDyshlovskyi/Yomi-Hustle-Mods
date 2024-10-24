extends "res://characters/states/Taunt.gd"

export  var guntrick = false








func _ready():
	pass


func _frame_15():
	if state_name == "Guntrick":
		current_tick += 2

func _frame_7():
	host.play_sound("Block")

func is_usable():
	return .is_usable() and not (guntrick and not host.opponent.busy_interrupt)
