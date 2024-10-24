extends ActionUIData

onready var jump_arc = $JumpArc

func fighter_update():


	jump_arc.hide()



	if fighter.combo_count > 0:



		jump_arc.show()

func get_data():
	if fighter.combo_count > 0:
		return .get_data()
	else :
		return "homing"
