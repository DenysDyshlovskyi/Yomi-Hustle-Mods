extends PanelContainer

const SCROLL_SPEED = 110.0



func _ready():
	
	
	pass






func _process(delta):
	if visible:
		$"%TickerText".rect_position.x -= SCROLL_SPEED * delta
		if $"%TickerText".rect_position.x < - $"%TickerText".rect_size.x:
			$"%TickerText".rect_position.x = $"%Ticker".rect_size.x






