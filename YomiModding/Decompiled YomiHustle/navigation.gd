extends Navigation2D

export (float) var CHARACTER_SPEED = 400.0
var path = []



func _input(event):
	if not event.is_action_pressed("click"):
		return 
	_update_navigation_path($Character.position, get_local_mouse_position())


func _update_navigation_path(start_position, end_position):
	
	
	
	path = get_simple_path(start_position, end_position, true)
	
	
	path.remove(0)
	set_process(true)


func _process(delta):
	var walk_distance = CHARACTER_SPEED * delta
	move_along_path(walk_distance)


func move_along_path(distance):
	var last_point = $Character.position
	while path.size():
		var distance_between_points = last_point.distance_to(path[0])

		
		if distance <= distance_between_points:
			$Character.position = last_point.linear_interpolate(path[0], distance / distance_between_points)
			return 

		
		distance -= distance_between_points
		last_point = path[0]
		path.remove(0)
	
	$Character.position = last_point
	set_process(false)
