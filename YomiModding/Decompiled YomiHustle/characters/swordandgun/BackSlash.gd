extends CharacterState







var move = true

func _frame_0():
	move = not (_previous_state_name() == "ImpaleTeleport" and host.reverse_state)


func _frame_2():
	if move:
		host.apply_force_relative("-14.0", "0")
