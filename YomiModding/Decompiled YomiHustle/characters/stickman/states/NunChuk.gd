extends CharacterState

export  var heavy = false

func on_got_perfect_parried():
	if heavy:
		host.hitlag_ticks += 4








