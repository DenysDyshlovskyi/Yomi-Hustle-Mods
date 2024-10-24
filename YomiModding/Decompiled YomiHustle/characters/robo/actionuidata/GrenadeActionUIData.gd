extends ActionUIData
onready var trajectory = $Trajectory

func fighter_update():
	trajectory.limit_symmetrical = not fighter.is_grounded()
