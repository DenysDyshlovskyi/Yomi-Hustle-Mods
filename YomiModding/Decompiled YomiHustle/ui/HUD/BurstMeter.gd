extends TextureProgress




const texture_1 = preload("res://ui/burst2.png")
const texture_2 = preload("res://ui/burst3.png")
export  var reverse = false

onready var ready_label = $ReadyLabel

var fighter: Fighter

func _ready():
	texture_progress = texture_2

func _process(delta):
	if is_instance_valid(fighter):
		value = fighter.burst_meter / float(fighter.MAX_BURST_METER)
		if fighter.bursts_available > 0:
			value = 1
			texture_progress = texture_2
			if not ready_label.visible:
				ready_label.show()
		else :
			texture_progress = texture_1
			if ready_label.visible:
				ready_label.hide()



















