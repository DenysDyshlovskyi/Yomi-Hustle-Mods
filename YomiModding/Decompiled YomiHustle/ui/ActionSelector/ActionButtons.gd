extends Control

class_name ActionButtons

signal action_selected(action, data, extra)
signal turn_ended()
signal action_clicked(action, data, extra)

signal opponent_ready()

const BUTTON_SCENE = preload("res://ui/ActionSelector/ActionButton.tscn")
const NUDGE_SCENE = preload("res://ui/ActionSelector/ActionUIData/NudgeActionUIData.tscn")
const BUTTON_CATEGORY_CONTAINER_SCENE = preload("res://ui/ActionSelector/ButtonCategoryContainer.tscn")
const BUTTON_CATEGORY_DISTANCE = 100

export  var player_id = 1

var fighter: Fighter
var fighter_extra: PlayerExtra


var buttons = []
var last_button = null
var current_action = null
var current_button = null
var current_extra = null
var current_data = null
var current_prediction = - 1
var button_pressed = null
var any_available_actions = false
var waiting_for_opponent_ready = false
var active = false
var turbo_mode = false
var game
var forfeit = false
var opposite_buttons = null
var locked_in = false
var can_lock_in = true
var attempting_lock_in = false
var lock_in_pressed = false
var continue_button
var spread_amount = 0.0
var spread_tween: SceneTreeTween = null
var nudge_button

var buffered_ui_actions = []

export  var opponent_action_buttons_path: NodePath
onready var opponent_action_buttons: ActionButtons = get_node(opponent_action_buttons_path)

var button_category_containers = {
}

func _input(event):
	if event is InputEventAction:
		if event.is_action_pressed("submit_action"):
			_on_submit_pressed()

func _ready():

	$"%SelectButton".connect("pressed", self, "_on_submit_pressed")

	buttons.append($"%ContinueButton")
	$"%UndoButton".connect("pressed", self, "_on_undo_pressed")
	if player_id == 1:
		$"%BottomRow".alignment = BoxContainer.ALIGN_END
		$"%TopRow".alignment = BoxContainer.ALIGN_END
		$"%TopRowDataContainer".move_child($"%DIContainer", 0)
		$"%TopRowDataContainer".grow_horizontal = Control.GROW_DIRECTION_END
	else :
		$"%BottomRow".alignment = BoxContainer.ALIGN_BEGIN
		$"%TopRow".alignment = BoxContainer.ALIGN_BEGIN
		$"%TopRowDataContainer".grow_horizontal = Control.GROW_DIRECTION_BEGIN
	$"%AutoButton".hint_tooltip = "Skips your turn when no actions are available."

	$"%DI".hint_tooltip = "Adjusts the angle and speed you are knocked back next time you are hit."
	$"%DI".connect("data_changed", self, "send_ui_action")
	$"%ReverseButton".connect("pressed", self, "send_ui_action", [null])
	$"%FeintButton".connect("pressed", self, "send_ui_action", [null])

	if not player_id == 1:
		var top_row_items = $"%TopRow".get_children()
		top_row_items.invert()
		for i in range(top_row_items.size()):
			$"%TopRow".move_child(top_row_items[i], i)
		$"%LastMoveTexture".rect_position.x += 40
	else :
		$"%LastMoveTexture".rect_position.x -= 40

	opponent_action_buttons.connect("action_clicked", self, "on_opponent_action_clicked")

func on_opponent_action_clicked(_action, _data, _extra):
	if current_button and current_button.data_node:
		current_button.data_node.on_opponent_button_selected(opponent_action_buttons.current_button)


	pass

func _get_opposite_buttons():
	return opposite_buttons

func _on_submit_pressed():
	lock_in_pressed = true
	yield (get_tree(), "idle_frame")


	yield (get_tree(), "idle_frame")
	if attempting_lock_in:
		return 
	attempting_lock_in = true
	while not can_lock_in:
		yield (get_tree(), "idle_frame")
	attempting_lock_in = false
	var data = null
	if current_button:
		data = current_button.get_data()
	if current_action:
		on_action_submitted(current_action, data)
	lock_in_pressed = false
	locked_in = true

func timeout():
	if active:
		_on_submit_pressed()

func _on_continue_pressed():
	on_action_submitted("Continue")

func _on_undo_pressed():
	on_action_submitted("Undo")

func space_pressed():
	if visible:
		if not $"%SelectButton".disabled and $"%SelectButton".visible:
			_on_submit_pressed()

func _physics_process(delta):
	if is_instance_valid(game):
		if not game.game_paused:
			visible = false

func _process(delta):
	$"%DI".set_flash(false)
	if active and is_instance_valid(fighter):
		if fighter.will_forfeit:
			on_action_submitted("Forfeit", null, null)
		if fighter.is_in_hurt_state() and fighter.busy_interrupt:
			$"%DI".set_flash(Utils.pulse(0.55, 0.1))
	$"%LastMoveTexture".visible = Global.show_last_move_indicators
	if (current_button and not current_button.visible):
		continue_button.set_pressed(true)
		continue_button.on_pressed()
	unpress_extra_on_lock_in()
	if buffered_ui_actions:
		_send_ui_action(buffered_ui_actions[ - 1])
		buffered_ui_actions = []
	
func unpress_extra_on_lock_in():
	var select_button: Button = $"%SelectButton"
	select_button.shortcut = preload("res://ui/ActionSelector/SelectButtonShortcut.tres")
	if lock_in_pressed:
		check_extra_button_pressed(fighter_extra)

func check_extra_button_pressed(node: Node):
	for child in node.get_children():
		if child is BaseButton:
			child.release_focus()
		else :
			check_extra_button_pressed(child)


func reset():
	for button_category_container in button_category_containers.values():
		button_category_container.free()
	for button in buttons:
		if is_instance_valid(button):
			if button.data_node:
				button.data_node.free()
			button.free()
	for data in $"%DataContainer".get_children():
		data.free()
	if fighter_extra:
		fighter_extra.free()
	
	button_category_containers.clear()



	current_action = null
	current_button = null
	last_button = null
	forfeit = false
	buttons = []

func init(game, id):
	reset()
	self.game = game
	fighter = game.get_player(id)
	$"%DI".visible = fighter.di_enabled
	fighter_extra = fighter.player_extra_params_scene.instance()
	fighter_extra.connect("data_changed", self, "extra_updated")
	game.connect("forfeit_started", self, "_on_forfeit_started")
	fighter_extra.set_fighter(fighter)
	turbo_mode = fighter.turbo_mode
	Network.action_button_panels[id] = self
	buttons = []


	var states = []
	for category in fighter.action_cancels:
		for state in fighter.action_cancels[category]:
			if state.show_in_menu and not state in states:
				states.append(state)
				create_button(state.name, state.title, state.get_ui_category(), state.data_ui_scene, BUTTON_SCENE, state.button_texture, state.reversible, state.flip_icon, state)

	sort_categories()
	connect("action_selected", fighter, "on_action_selected")
	fighter.connect("action_selected", self, "_on_fighter_action_selected")
	fighter.connect("forfeit", self, "_on_fighter_forfeit")
	hide()
	$"%TopRowDataContainer".add_child(fighter_extra)
	if player_id == 1:


		$"%CategoryContainer".move_child($"%TurnButtons", $"%CategoryContainer".get_children().size() - 1)
		$"%TopRowDataContainer".move_child(fighter_extra, 2)
	else :
		$"%TopRowDataContainer".move_child(fighter_extra, 0)
	continue_button = create_button("Continue", "Hold", "Movement", null, preload("res://ui/ActionSelector/ContinueButton.tscn"), null, false)
	continue_button.get_parent().remove_child(continue_button)
	continue_button["custom_fonts/font"] = null
	$"%TurnButtons".add_child(continue_button)
	$"%TurnButtons".move_child(continue_button, 1)


func _on_fighter_action_selected(_action, _data, _extra):
	pass

func _on_forfeit_started(id):
	hide()

func _on_fighter_forfeit():


	forfeit = true

func sort_categories():
	var children = $"%CategoryContainer".get_children()
	var categories = []
	for child in children:
		if child is ButtonCategoryContainer:
			$"%CategoryContainer".remove_child(child)
			categories.append(child)
	categories.sort_custom(self, "category_sort_func")
	for cat in categories:
		if cat is ButtonCategoryContainer:
			$"%CategoryContainer".add_child(cat)

func category_sort_func(a, b):
	var cat_map = {
		"Movement": 0, 
		"Attack": 1, 
		"Special": 2, 
		"Super": 3, 
		"Defense": 4, 
	}

	if player_id == 1:
		return cat_map[a.label_text] > cat_map[b.label_text]
	return cat_map[a.label_text] < cat_map[b.label_text]


func create_button(name, title, category, data_scene = null, button_scene = BUTTON_SCENE, texture = null, reversible = true, flip_icon = true, state = null):
	var button
	var data_node
	button = button_scene.instance()
	button.setup(name, title, texture)
	buttons.append(button)
	if state:
		button.state = state
	

	if not category in button_category_containers:
		var category_int = - 1
		if state:
			category_int = state.type
		create_category(category, category_int)
	var container = button_category_containers[category]
	container.add_button(button)
	if button.get("flip_icon") != null:
		button.flip_icon = flip_icon
	
	if button.get("earliest_hitbox") != null and state != null:
		button.earliest_hitbox = state.earliest_hitbox
	
	if button.get("is_guard_break") != null and state != null:
		button.is_guard_break = state.is_guard_break
	
	button.set_player_id(player_id)
	if data_scene:
		data_node = data_scene.instance()
		data_node.action_buttons = self
		data_node.state = state
		data_node.fighter = fighter
		$"%DataContainer".add_child(data_node)
		data_node.init()
	button.set_data_node(data_node)
	button.reversible = reversible
	button.connect("data_changed", self, "send_ui_action")
	button.container = container
	button.connect("was_pressed", self, "on_action_selected", [button])
	button.call_deferred("end_setup")
	$"%ButtonSoundPlayer".add_container(button)
	return button

func create_category(category, category_int = - 1):
	var scene = BUTTON_CATEGORY_CONTAINER_SCENE.instance()
	scene.fighter = fighter
	button_category_containers[category] = scene
	scene.category_int = category_int
	scene.show_behind_parent = true
	scene.init(category)

	scene.connect("prediction_selected", self, "_on_prediction_selected", [category])
	scene.game = game
	scene.player_id = player_id
	$"%CategoryContainer".add_child(scene)

func _on_prediction_selected(selected_category):
	for category in button_category_containers:
		if category != selected_category:
			button_category_containers[category].reset_prediction()
			button_category_containers[category].refresh()
	for category in button_category_containers:
		var prediction = button_category_containers[category].get_prediction()
		if prediction and button_category_containers[category].visible:
			current_prediction = button_category_containers[category].category_int
			send_ui_action()
			_get_opposite_buttons().send_ui_action()
			return 
	current_prediction = - 1
	send_ui_action()
	_get_opposite_buttons().send_ui_action()

func send_ui_action(action = null):
	buffered_ui_actions.append(action)

func _send_ui_action(action = null):
	current_extra = get_extra()
	if not is_instance_valid(game):
		return 
	if action == null:
		action = current_action
	if not button_pressed:
		action = "Continue"
		current_action = action

	if current_button:
		if current_button.data_node:

			var dir = fighter.get_opponent_dir()
			if current_extra and current_extra.has("reverse") and current_extra["reverse"]:
				dir *= - 1
			var data_facing = current_button.data_node.get_facing()
			if data_facing:
				if dir != data_facing:
					current_button.data_node.set_facing(dir)



	if action:
		yield (get_tree(), "idle_frame")
		emit_signal("action_clicked", action, current_button.get_data() if current_button else null, get_extra())




	can_lock_in = false
	yield (get_tree(), "idle_frame")
	can_lock_in = true

	update_select_button()

	update_buttons(false)

	if current_button:
		$"%ReverseButton".set_disabled( not current_button.is_reversible() if current_button.has_method("is_reversible") else not current_button.reversible)
		if current_button.state:
			$"%FeintButton".set_disabled( not current_button.state.can_feint())
		else :
			$"%FeintButton".set_disabled(true)
		$"%FeintButton".modulate = Color.white if fighter.feints > 0 else Color("d440b6")
		if not $"%FeintButton".disabled:
			$"%FeintButton".set_disabled( not fighter_extra.can_feint)
			if $"%FeintButton".disabled:
				$"%FeintButton".pressed = false

func extra_updated():
	if fighter_extra:
		fighter_extra.update_selected_move(current_button.state)
	if not fighter_extra.can_feint:
		$"%FeintButton".pressed = false
		$"%FeintButton".set_disabled(true)

	send_ui_action()

func on_action_selected(action, button):
	button_pressed = true
	for b in buttons:
		if button != b:
			b.set_pressed_no_signal(false)
	button.set_pressed_no_signal(true)
	if fighter_extra:
		fighter_extra.update_selected_move(button.state)
	var same_button = button == current_button
	current_button = button
	current_action = action


	for category in button_category_containers.values():
		category.refresh()
	for button in buttons:
		if button.data_node:
			button.data_node.hide()
			button.container.hide_data_container()
	
	last_button = button
	if button.data_node:
		call_deferred("show_button_data_node", button)

	if opponent_action_buttons.current_button and opponent_action_buttons.current_button.data_node:
		opponent_action_buttons.current_button.data_node.on_opponent_button_selected(current_button)
	if current_button and current_button.data_node:
		current_button.data_node.on_button_selected()
	
	$"%ReverseButton".set_disabled( not button.is_reversible() if button.has_method("is_reversible") else not button.reversible)
	if button.state:
		$"%FeintButton".set_disabled( not (button.state.can_feint() and fighter_extra.can_feint))
	else :
		$"%FeintButton".set_disabled(true)
	if not fighter_extra.can_feint:
		$"%FeintButton".set_pressed_no_signal(false)
	send_ui_action()

func show_button_data_node(button):
	yield (get_tree(), "idle_frame")
	button.data_node.show()
	var dir = fighter.get_opponent_dir()
	if current_extra and current_extra.has("reverse") and current_extra["reverse"]:
		dir *= - 1
	button.data_node.set_facing(dir)

	button.container.show_data_container()

func get_extra()->Dictionary:

	var extra = {
		"DI": $"%DI".get_data(), 
		"reverse": $"%ReverseButton".pressed and not $"%ReverseButton".disabled, 
		"feint": $"%FeintButton".pressed and not $"%FeintButton".disabled, 
		"prediction": _get_opposite_buttons().current_prediction, 
	}
	if fighter_extra:
		extra.merge(fighter_extra.get_extra())
	return extra

func on_action_submitted(action, data = null, extra = null):
	active = false
	extra = get_extra() if extra == null else extra

	$"%SelectButton".disabled = true
	emit_signal("turn_ended")
	$"%SelectButton".shortcut = null


	emit_signal("action_selected", action, data, extra)
	if not SteamLobby.SPECTATING:
		if Network.player_id == player_id:
			Network.submit_action(action, data, extra)
	



func get_visible_category_containers():
	var category_containers = []
	for container in button_category_containers.values():
		if container.any_buttons_visible():
			category_containers.append(container)
	return category_containers

func show_categories():
	for container in button_category_containers.values():
		container.hide()
	var category_containers = get_visible_category_containers()
	var num_button_categories = category_containers.size()

	for i in range(num_button_categories):
		if category_containers.size() <= i:
			break
		var scene = category_containers[i]
		scene.show()

func tween_spread():
	if spread_tween:
		spread_tween.kill()
	spread_amount = 0.0
	spread_tween = create_tween()
	spread_tween.set_ease(Tween.EASE_OUT)
	spread_tween.set_trans(Tween.TRANS_EXPO)
	spread_tween.tween_property(self, "spread_amount", 1.0, 0.2)





func reset_prediction():
	current_prediction = - 1
	var can_predict = fighter.opponent.state_interruptable and not fighter.opponent.busy_interrupt
	for container in button_category_containers.values():
		if can_predict:
			container.enable_predict_button()
		else :
			container.disable_predict_button()
		container.reset_prediction()

func update_cancel_category_air_type(category, force_grounded, force_aerial):
	for i in range(category.size()):
		if force_grounded:
			category[i] = category[i].replace("Aerial", "Grounded")
		if force_aerial:
			category[i] = category[i].replace("Grounded", "Aerial")

func update_buttons(refresh = true):

	for button in buttons:
		if button != continue_button:
			button.hide()

			if button != current_button:
				if button.data_node:
					button.data_node.hide()
					button.data_node.set_facing(fighter.get_facing_int())
					button.data_node.fighter_update()

	var state = fighter.state_machine.state
	var cancel_into
	if not fighter.busy_interrupt:
		cancel_into = (state.interrupt_into if not fighter.state_hit_cancellable else state.hit_cancel_into).duplicate(true)
		if turbo_mode and fighter.opponent.current_state().state_name != "Grabbed":
			if fighter.is_grounded():
				cancel_into.append("Grounded")
			else :
				cancel_into.append("Aerial")
		if fighter.feinting and fighter.should_free_cancel_allow_grounded_and_aerial_states() and fighter.opponent.current_state().busy_interrupt_type != CharacterState.BusyInterrupt.Hurt:
			cancel_into.append("Grounded")
			cancel_into.append("Aerial")
	else :
		cancel_into = state.busy_interrupt_into.duplicate(true)
	any_available_actions = false

	var extra = get_extra()
	var force_aerial = false
	var force_grounded = false
	
	if extra.has("input_grounded"):
		force_grounded = extra.input_grounded
	if extra.has("input_aerial"):
		force_aerial = extra.input_aerial
	update_cancel_category_air_type(cancel_into, force_grounded, force_aerial)

	var initiative = fighter.check_initiative()

	for button in buttons:
		var found = false
		if fighter.extremely_turbo_mode and not fighter.busy_interrupt:
			found = true
			$"%ReverseButton".set_disabled(false)
			any_available_actions = true
			button.set_disabled(false)
			button.show()
		else :
			for category in cancel_into:
				if not fighter.action_cancels.has(category):
					continue
				
				for cancel_state in fighter.action_cancels[category]:
					if not (cancel_state.state_name == button.action_name and \
					cancel_state.is_usable_with_grounded_check(force_aerial, force_grounded) and (cancel_state.allowed_in_stance())):
						continue

					
					if cancel_state.state_name == state.state_name:
						if fighter.state_hit_cancellable and not state.self_hit_cancellable and not turbo_mode:
							continue
						elif not fighter.state_hit_cancellable and not state.self_interruptable and not turbo_mode:
							continue
					if fighter.state_hit_cancellable and cancel_state.state_name in state.hit_cancel_exceptions:
						continue
					elif fighter.state_interruptable and cancel_state.state_name in state.interrupt_exceptions:
						continue
					var excepted = false
					if fighter.state_hit_cancellable:
						for c in state.hit_cancel_exceptions:
							if c in cancel_state.interrupt_from:
								excepted = true
					if not excepted and fighter.state_interruptable:
						for c in state.interrupt_exceptions:
							if c in cancel_state.interrupt_from:
								excepted = true
					if excepted:
						continue
					found = true
					
					$"%ReverseButton".set_disabled(false)
	
					
					any_available_actions = true
					button.set_disabled(false)
					button.show()
					button.set_initiative(initiative)
					break

	continue_button.show()
	if refresh or (current_button and not current_button.visible):
		continue_button.set_pressed(true)
		continue_button.on_pressed()



		
	show_categories()
	yield (get_tree(), "idle_frame")
	if is_instance_valid(continue_button):
		continue_button.set_disabled(false)

func update_select_button():
	var user_facing = game.singleplayer or Network.player_id == player_id
	if not user_facing:
		$"%SelectButton".disabled = true
	else :
		$"%SelectButton".disabled = game.spectating or locked_in

func activate(refresh = true):
	if visible and refresh:
		return 

	active = true
	locked_in = false



	if is_instance_valid(fighter):
		$"%DI".set_label("DI" + " x%.1f" % float(fighter.get_di_scaling(false)))
		var last_action_name = ReplayManager.get_last_action(fighter.id)

		if last_action_name and fighter.state_machine.states_map.has(last_action_name.action):
			last_action_name = last_action_name.action
		else :
			last_action_name = fighter.current_state().name

		var last_action: CharacterState = fighter.state_machine.states_map[last_action_name]
		$"%LastMoveTexture".texture = last_action.button_texture
		$"%LastMoveLabel".text = last_action.title if last_action.title else last_action.name
		$"%LastMoveTexture".visible = not last_action.is_hurt_state
		$"%LastMoveLabel".visible = not last_action.is_hurt_state
		$"%LastMoveData".visible = not last_action.is_hurt_state
		$"%LastMoveData".text = last_action.get_last_action_text()

	var user_facing = game.singleplayer or Network.player_id == player_id
	if Network.multiplayer_active:
		if user_facing:
			$"%YouLabel".show()
			modulate = Color.white
			Network.action_submitted = false
		else :
			$"%YouLabel".hide()
			modulate = Color("b3b3b3")
	else :
		$"%YouLabel".hide()

	if game.current_tick == 0:
		$"%UndoButton".set_disabled(true)
	else :
		$"%UndoButton".set_disabled(false)
	if Network.multiplayer_active or SteamLobby.SPECTATING:
		$"%UndoButton".hide()

	$"%ReverseButton".set_disabled(true)
	$"%ReverseButton".pressed = false
	$"%FeintButton".pressed = (Global.auto_fc or not user_facing) and fighter.feints > 0

	current_action = null
	current_button = null
	
	Network.turns_ready = {
		1: false, 
		2: false
	}
	show()

	







	


	if not user_facing:
		$"%SelectButton".disabled = true
	else :
		$"%SelectButton".disabled = game.spectating
		
	fighter_extra.hide()
	
	update_buttons(refresh)

	
	if not fighter.busy_interrupt:
		fighter_extra.show()
		fighter_extra.show_behind_parent = true
		fighter_extra.show_options()
		
	fighter_extra.reset()
	
	if fighter.dummy:
		on_action_submitted("ContinueAuto", null)
		hide()
		
	if fighter.will_forfeit:
		on_action_submitted("Forfeit", null, null)
		fighter.dummy = true

	fighter.any_available_actions = any_available_actions
	if user_facing and $"%AutoButton".pressed:
		if not any_available_actions:
			print("no available actions!")
			on_action_submitted("Continue", null)
			current_action = "Continue"

	$"%ReverseButton".hide()
	yield (get_tree(), "idle_frame")

	$"%ReverseButton".show()
	if not refresh:
		return 
	fighter.update_property_list()
	button_pressed = false
	send_ui_action("Continue")
	if user_facing:
		if Network.multiplayer_active:
			yield (get_tree().create_timer(0.25), "timeout")
		$"%SelectButton".shortcut = preload("res://ui/ActionSelector/SelectButtonShortcut.tres")






	if player_id == 1:
		if Network.p1_undo_action:
			var input = Network.p1_undo_action
			on_action_submitted(input["action"], input["data"], input["extra"])
			Network.p1_undo_action = null
	if player_id == 2:
		if Network.p2_undo_action:
			var input = Network.p2_undo_action
			on_action_submitted(input["action"], input["data"], input["extra"])
			Network.p2_undo_action = null


func _on_DIContainer_mouse_entered():
	pass
