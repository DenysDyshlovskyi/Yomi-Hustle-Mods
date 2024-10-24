extends "res://characters/states/Dash.gd"





onready var hurtbox_state = $HurtboxState

func spawn_dash_particle():
	if not same_as_last_state:
		.spawn_dash_particle()

func spawn_enter_particle():
	if not same_as_last_state:
		.spawn_enter_particle()

func play_enter_sfx():
	if not same_as_last_state:
		.play_enter_sfx()


func _enter():
	._enter()
	if _previous_state_name() == "DashForward":
		hurtbox_state.start_tick = 0
	else :
		hurtbox_state.start_tick = 3

	if not host.sprite.is_connected("frame_changed", self, "on_sprite_frame_changed"):
		host.sprite.connect("frame_changed", self, "on_sprite_frame_changed")
	setup_hurtboxes()





func _frame_4():
	if _previous_state_name() != "DashForward":
		if data:
			if data.get("x") == 100:
				host.add_juke_pip()

func on_sprite_frame_changed():
	if not active:
		return 
	if host.sprite.frame == 2 or host.sprite.frame == 5:
		host.play_sound("Walk1")
	if host.sprite.frame == 3 or host.sprite.frame == 0:
		host.play_sound("Walk2")
