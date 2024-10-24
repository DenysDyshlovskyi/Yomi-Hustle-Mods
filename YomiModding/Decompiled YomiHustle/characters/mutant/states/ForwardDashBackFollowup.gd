extends BeastState

func _frame_0():
	host.colliding_with_opponent = false


func on_got_blocked():
	host.colliding_with_opponent = true
	host.reset_momentum()









