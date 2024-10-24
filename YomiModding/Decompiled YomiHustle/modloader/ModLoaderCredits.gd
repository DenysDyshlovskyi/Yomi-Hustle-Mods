extends Window

func _ready():
	$"%Close".connect("pressed", self, "_close_clicked")
	

	hide()

func _close_clicked():
	hide()
