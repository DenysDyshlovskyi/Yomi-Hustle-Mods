extends "res://ObjectState.gd"


export  var pitch_var = 0.1
export  var pitch_scale = 1


func setup_audio():
	if enter_sfx:
		enter_sfx_player = VariableSound2D.new()
		add_child(enter_sfx_player)
		enter_sfx_player.bus = "Fx"
		enter_sfx_player.stream = enter_sfx
		enter_sfx_player.volume_db = enter_sfx_volume
		enter_sfx_player.pitch_variation = pitch_var

	if sfx:
		sfx_player = VariableSound2D.new()
		add_child(sfx_player)
		sfx_player.bus = "Fx"
		sfx_player.stream = sfx
		sfx_player.volume_db = sfx_volume
		sfx_player.pitch_variation = pitch_var
		sfx_player.pitch_scale_ = pitch_scale
