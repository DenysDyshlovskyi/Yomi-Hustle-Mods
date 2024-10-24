extends Control

var buttons = []

signal match_ready(data)
signal opened()
signal mods_loaded()

var pressed_button = null
var hovered_characters = {}
var selected_characters = {}
var selected_styles = {
			1: null, 
			2: null
		}
	
var singleplayer = true
var current_player = 1
var network_match_data = {}










var _Global = Network



var customCharNumber = 0

var charList = []
var loadedChars = []
var buttonsToLoad = []

var charPortrait = {}
var errorMessage = {}

var loadThread
var loadThread2
var currentlyLoading = false




var charPage = 0;
var buttons_x = 0;
var maxRows = 5;

var arrowSprites = [null, null]

onready var bttContainer = self.get_node("%CharacterButtonContainer")
onready var loading_text = $LoadingText
onready var game_settings_panel_container = $"%GameSettingsPanelContainer"
onready var scroll_container = $ScrollContainer
onready var go_button = $"%GoButton"
onready var selecting_label = $"%SelectingLabel"
onready var h_box_container = $HBoxContainer
onready var quit_button = $"%QuitButton"



var btt_disableTimer = 0



var name_to_folder = {}
var name_to_index = {}
var hash_to_folder = {}



var loadingLabel
var loadingText = ""
var retract_loaded = false
var labelTimer = 0

var loaded_mods = false

var pageLabel
var searchBar

func _ready():
	bttContainer.hide()
	loading_text.show()
	go_button.hide()
	
	$"%GoButton".connect("pressed", self, "go")

	$"%QuitButton".connect("pressed", self, "quit")
	Network.connect("character_selected", self, "_on_network_character_selected")
	Network.connect("match_locked_in", self, "_on_network_match_locked_in")
	var dir = Directory.new()

	searchBar = load("res://cl_port/searchbar.tscn").instance()
	searchBar.connect("text_entered", self, "on_searched")

	self.add_child(searchBar)
	
	if (dir.file_exists("res://characters/PlayerInfo.tscn") and not dir.file_exists("res://ui/PlayerInfo.tscn")):
		var pi_scene = load("res://characters/PlayerInfo.tscn").instance()
		ModLoader.saveScene(pi_scene, "res://ui/PlayerInfo.tscn")

	
	var h = File.new()
	h.open("res://cl_port/headers/sample.header", File.READ)
	sample_header = h.get_buffer(h.get_len())
	h.close()
	h.open("res://cl_port/headers/oggstr.header", File.READ)
	oggstr_header = h.get_buffer(h.get_len())
	h.close()
	loadingLabel = createLabel("Character Loaded", "Loaded", 0, 345)
	loadingLabel.percent_visible = 0
	
	
	_Global.css_instance = self
	self.visible = false

	Global.mods_loaded = false
	loadThread2 = Thread.new()
	loadThread2.start(self, "load_mods")


	yield (self, "mods_loaded")

	
	loaded_mods = true
	yield (get_tree(), "idle_frame")
	net_updateModLists()
	yield (get_tree(), "idle_frame")
	Global.mods_loaded = true
	bttContainer.show()
	go_button.show()
	loading_text.hide()

func load_mods():
	var dir = Directory.new()
	hash_to_folder = {}
	serverMods = []
	Network.hash_to_folder = {}
	if ( not dir.dir_exists("user://char_cache")):
		dir.make_dir("user://char_cache")
	charPackages = {}
	var caches = ModLoader._get_all_files("user://char_cache", "pck")
	var time = Time.get_ticks_msec()
	for zip in ModLoader._modZipFiles:
		Global.loading_character = str(zip).split("/")[ - 1]
		var gdunzip = load("res://modloader/gdunzip/gdunzip.gd").new()
		gdunzip.load(zip)
		var folder = ""
		for modEntryPath in gdunzip.files:
			if (modEntryPath.find(".import") == - 1):
				folder = "res://" + modEntryPath.rsplit("/")[0]
				break
		var hashy = ModLoader._hash_file(zip)
		hash_to_folder[hashy] = folder
		Network.hash_to_folder[hashy] = folder
		var md = ModLoader._readMetadata(folder + "/_metadata")
		if (md == null):
			continue
		var is_serverSided = true
		if md.has("client_side"):
			if md["client_side"]:
				is_serverSided = false
		if is_serverSided:
			serverMods.append(hashy)
		for f in caches:
			var fName = f.replace("user://char_cache/", "")
			if fName.find(md.name.validate_node_name()) == 0 and fName.find(md.author.validate_node_name()) != - 1:
				if fName.find(hashy) == - 1 or fName.find(clVersion.validate_node_name()) == - 1:
					dir.remove(f)
				else :
					charPackages[md.name] = f
		var new_time = Time.get_ticks_msec()


	call_deferred("on_mods_load_finished")
	

func on_mods_load_finished():
	emit_signal("mods_loaded")

	loadThread2.wait_to_finish()
	pass

func _on_network_character_selected(player_id, character, style = null):
	selected_characters[player_id] = character
	selected_styles[player_id] = style
	if Network.is_host() and player_id == Network.player_id:
		$"%GameSettingsPanelContainer".hide()
	if selected_characters[1] != null and selected_characters[2] != null:

		if Network.is_host():
			Network.rpc_("send_match_data", get_match_data())

func _on_network_match_locked_in(match_data):
	network_match_data = match_data
	if SteamLobby.LOBBY_ID != 0 and SteamLobby.OPPONENT_ID != 0:
		Steam.setLobbyMemberData(SteamLobby.LOBBY_ID, "character", match_data.selected_characters[SteamLobby.PLAYER_SIDE].name)
	if (loadThread != null):
		loadThread.wait_to_finish()
	loadThread = Thread.new()
	loadThread.start(self, "net_async_loadOtherChar")

func reset():
	hide()

func init(singleplayer = true):
	show()
	emit_signal("opened")


	for button in buttons:
		button.disabled = false


	$"%GoButton".disabled = true
	$"%GoButton".show()
	self.singleplayer = singleplayer
	$"%GameSettingsPanelContainer".init(singleplayer)


	$"%SelectingLabel".text = "P1 SELECT YOUR CHARACTER" if singleplayer else "SELECT YOUR CHARACTER"
	$"%SelectingLabel".modulate = Color.dodgerblue if singleplayer else Color.white
	$"%P1Display".init()
	$"%P2Display".init()
	if Network.steam:
		$"%GameSettingsPanelContainer".hide()


	selected_styles = {
		1: null, 
		2: null
	}
	
	hovered_characters = {
		1: null, 
		2: null, 
	}

	selected_characters = {
		1: null, 
		2: null
	}
	
	current_player = 1 if singleplayer else Network.player_id
	
	if not singleplayer:
		if current_player == 1:
			$"%P2Display".set_enabled(false)
			$"%P1Display".load_last_style()
		else :
			$"%P1Display".set_enabled(false)
			$"%P2Display".load_last_style()
		$"%GoButton".hide()
	else :
		$"%P2Display".load_style_button.save_style = false
	$"%P1Display".load_last_style()
	pressed_button = null
	buttons = []
	for child in $"%CharacterButtonContainer".get_children():
		child.queue_free()
	for name in Global.name_paths:


		var button = preload("res://ui/CSS/CharacterButton.tscn").instance()
		if name in Global.characters_cache:
			button.character_scene = Global.get_cached_character(name)
		else :
			continue
		$"%CharacterButtonContainer".add_child(button)


		button.text = name
		buttons.append(button)
		if not button.is_connected("pressed", self, "_on_button_pressed"):
			button.connect("pressed", self, "_on_button_pressed", [button])
			button.connect("mouse_entered", self, "_on_button_mouse_entered", [button])
		$ButtonSoundPlayer.add_container($"%CharacterButtonContainer")
		$ButtonSoundPlayer.setup()
	_on_button_mouse_entered(buttons[0])
	
func get_character_data(button):
	var data = {}
	var scene = button.character_scene.instance()
	data["name"] = scene.name
	scene.free()
	return data











func get_display_data(button):
	var data = {}
	if not isCustomChar(button.name) or (button.name in loadedChars):
		var scene = button.character_scene.instance()
		data["name"] = scene.name
		data["portrait"] = scene.character_portrait
		scene.free()
	else :
		data["name"] = button.name
		data["portrait"] = charPortrait[button.name]

		if (button.name in errorMessage.keys()):
			data["name"] = errorMessage[button.name]
	return data

func _on_button_mouse_entered(button):
	var data = get_display_data(button)
	display_character(current_player, data)
	pass

func display_character(id, data):
	var display = $"%P1Display" if id == 1 else $"%P2Display"
	display.load_character_data(data)





















func _on_button_pressed(button):
	if btt_disableTimer > 0 or currentlyLoading:
		button.set_pressed_no_signal(false)
		return 
	var miss = []
	if (isCustomChar(button.name)):
		loadThread = Thread.new()
		loadThread.start(self, "async_loadButtonChar", button)
	else :
		buffer_select(button)

	for button in buttons:
		button.set_pressed_no_signal(false)

func quit():
	if Network.multiplayer_active:
		Network.stop_multiplayer()

	SteamLobby.quit_match()
	Global.reload()

func get_match_data():
	if singleplayer:
		selected_styles = {
			1: $"%P1Display".selected_style, 
			2: $"%P2Display".selected_style
		}
	var data = {
		"singleplayer": singleplayer, 
		"selected_characters": selected_characters, 
		"selected_styles": selected_styles, 

	}
	if singleplayer or Network.is_host():
		randomize()
		data.merge({"seed": randi()})
	
	if SteamLobby.LOBBY_ID != 0 and SteamLobby.MATCH_SETTINGS:
		data.merge(SteamLobby.MATCH_SETTINGS)
	else :
		data.merge($"%GameSettingsPanelContainer".get_data())
	return data

func go():
	if not singleplayer:
		emit_signal("match_ready", network_match_data)
	else :
		emit_signal("match_ready", get_match_data())
	hide()

func _process(delta):
	Global.css_open = visible
	if not loaded_mods:
		return 

	


	
	var makeButtons = false
	var curButtons = bttContainer.get_children()

	var isThereCustoms = false
	var bNames = []
	for b in curButtons:
		if isCustomChar(b.text):
			makeButtons = true
			break
		elif not (b.text in Global.name_paths.keys()):
			isThereCustoms = true
			break
	if ( not isThereCustoms):
		makeButtons = true
	
	if (makeButtons):
		call_deferred("createButtons")
		createdButtons = true

	var btts = bttContainer.get_children()

	go_button.rect_position.y = 177 + min(bttContainer.rect_size.y, scroll_container.rect_size.y)

	if (btt_disableTimer > 0):
		btt_disableTimer -= delta * 60
		btt_disableTimer = max(btt_disableTimer, 0)

	for j in len(btts):
		var b = btts[j]
		if ( not b.is_visible()):
			continue

		
		if ( not net_isCharacterAvailable(b.name)):
			b.disabled = true

	var connected = SteamLobby.connected()
	for j in len(btts):
		var b = btts[j]
		if isCustomChar(b.name):
			b.visible = (connected and SteamLobby.LOBBY_CHARLOADER_ENABLED) or not connected
			

	searchBar.visible = $ScrollContainer.get_v_scrollbar().is_visible_in_tree()

	
	$"%QuitButton".disabled = currentlyLoading

	
	if not updatedNetworkLists:
		net_updateModLists()
		updatedNetworkLists = true

	
	loadingLabel.text = loadingText

	if (retract_loaded):
		if labelTimer == 0:
			loadingLabel.percent_visible += delta * 3
		if (loadingLabel.percent_visible >= 1):
			labelTimer += delta
		if (labelTimer > 2):
			loadingLabel.percent_visible -= delta * 2
			if (loadingLabel.percent_visible - delta * 4 <= 0):
				retract_loaded = false
				loadingLabel.percent_visible = 0
	
	if _Global.isSteamGame:
		Network.multiplayer_host = Network.steam_isHost

	
	if (buffer_go):
		if loadThread != null:
			loadThread.wait_to_finish()
		buffer_go = false
		go()


func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT and event.pressed:
			if event.position.y > 240 and event.position.y < 280:
				var pageChange = 0
				if event.position.x > 640 - 14:
					pageChange = 1
				elif event.position.x < 14:
					pageChange = - 1
				if (pageChange != 0):
					charPage += pageChange
					btt_disableTimer = 20
					searchBar.release_focus()

func dict_findKey(_dictionary, _value):
	for key in _dictionary.keys():
		if (_dictionary[key] == _value):
			return key
	return - 1

func folder_to_name(_folder):
	return dict_findKey(name_to_folder, _folder)

func folder_to_hash(_folder):
	return dict_findKey(hash_to_folder, _folder)

func loadingLabel_start():
	retract_loaded = false
	loadingLabel.percent_visible = 1

func loadingLabel_vanish():
	retract_loaded = true
	labelTimer = 0

func loadingLabel_stop():
	loadingLabel.percent_visible = 0
	retract_loaded = false




var curModFolder
var curFighter
var curBttName

func update_fighter_vars(_name, _charPath, _bttName):
	curModFolder = "res://" + _charPath.split("://")[1].split("/")[0]
	curFighter = str("F-" + folder_to_hash(curModFolder) + "__" + _name).validate_node_name()

	curBttName = _name
	if (_bttName != ""):
		curBttName = _bttName.substr(0, 10)



var serverMods = []
var charPackages = {}
onready var clVersion = ModLoader.CL_VERSION


var sample_header
var oggstr_header




func addCustomChar(_name, _charPath, _bttName = ""):
	while not loaded_mods:
		yield (get_tree(), "idle_frame")
	update_fighter_vars(_name, _charPath, _bttName)
	if not (curFighter in name_to_folder.keys()):
		buttonsToLoad.append([_name, _charPath, _bttName])
		charList.append([_name, _charPath, _bttName])
		name_to_folder[curFighter] = curModFolder
		name_to_index[curFighter] = len(charList) - 1
		ModLoader.add_character_folder(curModFolder)


func addCharButton(_name, _charPath, _bttName = ""):
	update_fighter_vars(_name, _charPath, _bttName)

	if (bttContainer.get_node_or_null(curFighter) == null):
		customCharNumber += 1







		
		var char_button = load("res://ui/CSS/CharacterButton.tscn").instance()
		bttContainer.add_child(char_button)
		char_button.text = curBttName
		char_button.name = curFighter
		
		
		_importHolderPortrait(curModFolder, _charPath, curFighter)

		






func loadListChar(index, hideName = false):
	currentlyLoading = true
	var _name = charList[index][0]
	var _charPath = charList[index][1]
	var _bttName = charList[index][2]

	update_fighter_vars(_name, _charPath, _bttName)

	if (curFighter in loadedChars):
		return []

	loadingLabel_start()
	
	var displayName = curFighter if not hideName else "Opponent's Character"

	var miss = _createImportFiles(curModFolder, displayName, _charPath)
	
	loadingText = "Loading " + getCharName(displayName) + " scene..."

	
	
	var char_scene
	if (miss == []):
		char_scene = load(_charPath).instance()
		char_scene.name = curFighter
	else :
		errorMessage[curFighter] = "ERROR - these files are missing:"
		for f in miss:
			errorMessage[curFighter] += "\n" + f
	
	ModLoader.saveScene(char_scene, _charPath)

	
	bttContainer.get_node(curFighter).character_scene = load(_charPath)
	
	if (miss != []):
		loadingLabel_stop()
		return miss

	loadedChars.append(curFighter)
	Global.name_paths[curFighter] = _charPath

	return miss




func getButtonHeight(_divisions):
	var h = 60
	if (_divisions > 5):
		_divisions = 5
	if (_divisions > 1):
		h = 76 / 2
		if (_divisions > 3):
			h = 140 / _divisions
	return h

func updateButtonHeight(_divisions):











	pass

func async_loadButtonChar(button):
	var miss = loadListChar(name_to_index[button.name])
	_on_button_mouse_entered(button)
	
	if (miss == []):
		buffer_select(button)
	loadingText = getCharName(button.name) + " Loaded"
	loadingLabel_vanish()
	currentlyLoading = false


func buffer_select(button):
	var data = get_character_data(button)
	var display_data = get_display_data(button)
	display_character(current_player, display_data)
	selected_characters[current_player] = data
	
	if singleplayer and current_player == 1:
		current_player = 2
		$"%SelectingLabel".text = "P2 SELECT YOUR CHARACTER"
		$"%SelectingLabel".modulate = Color.red
	else :
		for button in buttons:
			button.disabled = true
		if singleplayer:
			$"%GoButton".disabled = false
	if not singleplayer:
		Network.select_character(data, $"%P1Display".selected_style if current_player == 1 else $"%P2Display".selected_style)


func createButtons():
	
	if (len(buttonsToLoad)) == 0:
		_Global.default_chars = len(bttContainer.get_children())
		return 

	var prevBtts = bttContainer.get_children()
	var prevChars = []
	var prevCharNames = []

	for child in prevBtts:
		if ( not isCustomChar(child.text) and not (child.text in prevCharNames)):
			prevChars.append([child.character_scene, child.text])
			prevCharNames.append(child.text)
		child.free()

	_Global.default_chars = len(prevChars)

	loadedChars = []
	buttons = []

	
	for charInfo in prevChars:
		var button = preload("res://ui/CSS/CharacterButton.tscn").instance()
		button.character_scene = charInfo[0]
		$"%CharacterButtonContainer".add_child(button)
		button.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
		button.text = charInfo[1]
	
	
	customCharNumber = 0


	for data in buttonsToLoad:
		addCharButton(data[0], data[1], data[2])


	
	for button in bttContainer.get_children():
		buttons.append(button)
		if not button.is_connected("pressed", self, "_on_button_pressed"):
			button.connect("pressed", self, "_on_button_pressed", [button])
			button.connect("mouse_entered", self, "_on_button_mouse_entered", [button])
	$ButtonSoundPlayer.add_container($"%CharacterButtonContainer")
	$ButtonSoundPlayer.setup()




var updatedNetworkLists = false
var createdButtons = false

var buffer_go = false

func on_searched(text):
	var btts = bttContainer.get_children()
	for j in len(btts):
		var b = btts[j]
		if ( not b.is_visible()):
			continue

		
		var searchFound = (b.text.to_lower().find(text.to_lower()) != - 1 or searchBar.text == "")

		if searchFound:

			b.grab_focus()






func textureGet(imagePath):
	var image = Image.new()
	var err = image.load(imagePath)
	if err != OK:
		return 0
	var tex = ImageTexture.new()
	tex.create_from_image(image, 0)
	return tex

func isCustomChar(_name):
	return _name.find("F-") == 0

func getCharName(_fullName):
	if (_fullName.find("__") != - 1):
		return _fullName.split("__")[1]
	return _fullName

func retro_charName(_name):
	if (_name in name_to_index.keys()):
		return _name
	var realName = getCharName(_name)
	for k in name_to_index.keys():
		if getCharName(k) == realName:
			return k
	return name_to_index.keys()[0]

func createLabel(_text, _name, _x, _y, _from = self):
	var label = Label.new()
	label.text = _text
	label.name = _name
	label.set_position(Vector2(_x, _y))
	_from.add_child(label)
	return label


var enable_online_go = false
func net_async_loadOtherChar():
	print("there should be 2 of these")
	for c in selected_characters.values():
		if (c != null):
			if (isCustomChar(c.name)):
				loadListChar(name_to_index[c.name], true)
				loadingText = "Character Loaded"
				loadingLabel_vanish()
				currentlyLoading = false

	if not Network.multiplayer_host:
		net_sendPacket("go_button_activate")
		
	else :
		$"%GoButton".show()
		$"%GoButton".connect("pressed", self, "net_startMatch")
		if enable_online_go:
			$"%GoButton".disabled = false
			enable_online_go = false

func net_startMatch():
	buffer_go = true
	net_sendPacket("go_button_pressed")
	

func net_updateModLists():
	Network.normal_mods = []
	Network.char_mods = []

	var i = 0
	for mod in ModLoader.active_mods:
		if hash_to_folder[mod[0]] in ModLoader.charFolders:
			Network.char_mods.append(mod[0])
		else :
			if (mod[0] in serverMods):
				Network.normal_mods.append(mod[0])
		i += 1


func net_loadReplayChars(_replayChars):
	var rc = _replayChars
	if rc != []:
		if (isCustomChar(rc[0])):
			loadListChar(name_to_index[retro_charName(rc[0])])
		if (isCustomChar(rc[1])):
			loadListChar(name_to_index[retro_charName(rc[1])])

func net_isCharacterAvailable(_charName):
	var custom = isCustomChar(_charName)
	if custom and not SteamLobby.LOBBY_CHARLOADER_ENABLED and SteamLobby.LOBBY_ID != 0:
		return false
	if ( not singleplayer and custom and (Network.player1_chars != [] or Network.player2_chars != [])):
		var foundIt1 = false
		var foundIt2 = false
		for m in Network.player1_chars:
			if (hash_to_folder.has(m)):
				if (name_to_folder[_charName] == hash_to_folder[m]):
					foundIt1 = true
					break
		for m in Network.player2_chars:
			if (hash_to_folder.has(m)):
				if (name_to_folder[_charName] == hash_to_folder[m]):
					foundIt2 = true
					break
		if ( not foundIt1 or not foundIt2):
			return false
	return true

func net_sendPacket(name):
	if (_Global.isSteamGame):
		var fullData = {"_packetName": name}
		SteamLobby._send_P2P_Packet(SteamLobby.OPPONENT_ID, fullData)
	else :
		Network.rpc_(name)




func writeHex(_file, _hexList = [], _bits = 64):
	for h in _hexList:
		if _bits == 8:
			_file.store_8(h)
		elif _bits == 16:
			_file.store_8(h)
		elif _bits == 32:
			_file.store_16(h)
		else :
			_file.store_64(h)

var hexVal = {
	"0": 0, 
	"1": 1, 
	"2": 2, 
	"3": 3, 
	"4": 4, 
	"5": 5, 
	"6": 6, 
	"7": 7, 
	"8": 8, 
	"9": 9, 
	"A": 10, 
	"B": 11, 
	"C": 12, 
	"D": 13, 
	"E": 14, 
	"F": 15
}

func writeStringHex(_file, _stringList = []):
	for s in _stringList:
		if (s[0] == "0" and s[1] == "x"):
			var num = _stringList.replace("0x", "").replace(" ", "")
			for i in len(num) / 2:
				var result = hexVal[num[i * 2]] * 16 + hexVal[num[i * 2 + 1]]
				_file.store_8(result)
		else :
			_file.store_string(s)


func save_stex(image, save_path):
	var tmppng = "%s-tmp.png" % [save_path]
	image.save_png(tmppng)
	var pngf = File.new()
	pngf.open(tmppng, File.READ)
	var pnglen = pngf.get_len()
	var pngdata = pngf.get_buffer(pnglen)
	pngf.close()
	Directory.new().remove(tmppng)
	var stexf = File.new()
	stexf.open(save_path, File.WRITE)
	stexf.store_string("GDST")
	stexf.store_32(image.get_width())
	stexf.store_32(image.get_height())
	stexf.store_32(0)
	stexf.store_32(118489088)
	stexf.store_32(1)
	stexf.store_32(pnglen + 6)
	stexf.store_string("PNG ")
	stexf.store_buffer(pngdata)
	stexf.close()


func save_sample(og_file, dest_file):

	
	var f = File.new()
	f.open(og_file, File.READ)

	
	f.seek(22)
	var channels = f.get_8()
	f.seek(24)
	var sRate = f.get_32()
	
	
	var ind = 40
	f.seek(ind - 4)
	var data32 = f.get_32()
	while data32 != 1635017060:
		ind += 1
		f.seek(ind - 4)
		data32 = f.get_32()

	
	f.seek(ind)
	var leng = f.get_32()
	
	
	f.seek(ind + 4)
	var fullWav = f.get_buffer(leng)

	leng = leng * 2
	
	f.close()

	
	f.open(dest_file, File.WRITE)

	
	f.store_buffer(sample_header)

	
	
	
	
	var numb = channels + 1
	if (sRate != 44100):
		numb += 1
	
	
	writeHex(f, [0, numb, 0, 0], 8)
	
	
	writeHex(f, [512])
	f.store_8(0)
	
	
	f.store_32(leng)
	f.store_buffer(fullWav)

	
	var wrote = 0
	var zeroChunk = 8
	for i in floor(leng / 2 / zeroChunk):
		writeHex(f, [0], 8 * zeroChunk)
		wrote += 8
	for i in leng / 2 - wrote:
		writeHex(f, [0], 8)
	
	
	writeHex(f, [3, 0, 0, 0], 8)
	writeHex(f, [3, 0, 0, 0, 1, 0, 0, 0], 8)
	
	
	if (sRate != 44100):
		writeHex(f, [7, 0, 0, 0, 3, 0, 0, 0], 8)
		f.store_32(sRate)
	
	if (channels == 2):
		writeHex(f, [8, 0, 0, 0, 2, 0, 0, 0], 8)
		writeHex(f, [1, 0, 0, 0], 8)
	
	
	f.store_string("RSRC")
	f.close()


func save_oggstr(og_file, dest_file):
	var f = File.new()
	f.open(og_file, File.READ)
	var _len = f.get_len()
	var buf = f.get_buffer(_len)
	f.close()

	f.open(dest_file, File.WRITE)
	f.store_buffer(oggstr_header)
	

	
	
	var len_bytes = [_len & 255, (_len & (65535)) >> 8, (_len & (16777216)) >> 16, _len >> 24]
	writeHex(f, len_bytes, 8)
	f.store_buffer(buf)
	f.store_string("RSRC")
	f.close()
	


func _importHolderPortrait(folder, scenePath, charName):
	var sc

	var f = File.new()
	f.open(scenePath, File.READ)
	var portPath = "res://characters/stickman/sprites/idle.png"
	var content = f.get_as_text()
	var portSource = 0
	var portSourceInd = content.find("character_portrait = ExtResource")

	if (portSourceInd != - 1):
		var startNumInd = portSourceInd + 33
		portSource = int(content.substr(startNumInd, content.find(" )", portSourceInd) - startNumInd))
	
		f.seek(0)
		var ids = ""
		var line = ""
		

		while ids != str(portSource) + "]":
			line = f.get_line().replace("\n", "").replace("", "")
			var split = line.split("id=")
			if split.size() <= 1:
				continue
			ids = line.split("id=")[1]
			if f.eof_reached():
				sc = load("res://characters/BaseChar.tscn").instance()
				sc.name = "Error\ncharacter scene must be unedited"
				ModLoader.saveScene(sc, scenePath)

				return scenePath
				break
	
		portPath = line.split("=")[1].split(" typ")[0].replace("\"", "")

	f.close()
	charPortrait[charName] = textureGet(portPath)


func _validateScene(scenePath, _modFolder):
	var f = File.new()
	var dir = Directory.new()
	f.open(scenePath, File.READ)
	var hintMsg = []
	var missing = []
	var line = "]"
	var sceneName = scenePath.replace(scenePath.get_base_dir() + "/", "")

	var otherScenes = []
	while line.find("]") != - 1:
		line = f.get_line().replace("\n", "").replace("", "")
		if line == "":
			break
		if (line.find("gd_scene") == 1):
			f.get_line()
			continue
		var resPath = line.split("path=\"")[1].split("\" type=")[0]
		loadingText = "Validating" + sceneName + "..."
		if not dir.file_exists(resPath):
			if not ResourceLoader.exists(resPath):
				var fullMiss = resPath
				missing.append(fullMiss)
				if (resPath.find(_modFolder) == - 1):
					hintMsg = [
						"## NOTICE: all of the following paths are being read from \"" + sceneName + "\".", 
						"## godot automatically generates all of these paths depending on their location in the FileSystem tab."
					]
		elif resPath.find(".tscn") != - 1:
			otherScenes.append(resPath)
	
	for s in otherScenes:
		missing += _validateScene(s, _modFolder)
	return hintMsg + missing


var p
func _import_start():
	p = PCKPacker.new()
	p.pck_start("user://imagepack.pck")

	var dir = Directory.new()
	dir.make_dir("user://mod_temp")

func _import_copy(destFile):
	var dir = Directory.new()
	dir.copy("user://imagepack.pck", destFile)

func _import_end():
	p.flush()

	ProjectSettings.load_resource_pack("user://imagepack.pck")

func _createImportFiles(folder, _charName, _charPath):
	var dir = Directory.new()

	
	var md = ModLoader._readMetadata(folder + "/_metadata")
	var modName = md.name
	if (modName in charPackages.keys()):
		loadingText = "Loading Cached Package"
		ProjectSettings.load_resource_pack(charPackages[modName])
		return []
	
	_import_start()

	var assets = ModLoader._get_all_files(folder, "png") + ModLoader._get_all_files(folder, "wav") + ModLoader._get_all_files(folder, "ogg")
	var delList = []
	
	var missingFiles = []

	for i in len(assets):
		if ( not dir.file_exists(assets[i] + ".import")):
			missingFiles.append(assets[i] + ".import")
		else :
			loadingText = "Loading " + getCharName(_charName) + " - " + str(int((float(i) / len(assets)) * 100)) + "%"
			
			
			var c = ConfigFile.new()
			c.load(assets[i] + ".import")
			var dest = c.get_value("remap", "path")

			if ( not dir.file_exists(dest)):
				
				var tmpFile = "user://mod_temp/" + dest.split("://.import/")[1]
				if (dest.ends_with(".stex")):
					var img = Image.new()
					img.load(assets[i])
					save_stex(img, tmpFile)
				elif (dest.ends_with(".oggstr")):
					save_oggstr(assets[i], tmpFile)
				else :
					save_sample(assets[i], tmpFile)
				
				
				p.add_file(dest, tmpFile)
				delList.append(tmpFile)
	
	
	if (dir.dir_exists(folder + "/.import")):
		var imports = ModLoader._get_all_files(folder)
		for f in imports:
			p.add_file("res://.import/" + f.split(".import/")[1], f)
	
	_import_end()

	
	var imports = ModLoader._get_all_files(folder, "import")
	for f in imports:
		if (dir.file_exists(f.replace(".import", ""))):
			var im = ConfigFile.new()
			im.load(f)
			var expected = im.get_value("remap", "path")
			if not dir.file_exists(expected):
				missingFiles.append(expected)
	
	for f in delList:
		dir.remove(f)
	dir.remove("user://mod_temp")
	
	missingFiles += _validateScene(_charPath, name_to_folder[curFighter])

	if (missingFiles == []):
		_import_copy("user://char_cache/" + modName.validate_node_name() + "-" + md.author.validate_node_name() + "-" + folder_to_hash(folder) + "-" + clVersion.validate_node_name() + ".pck")

	return missingFiles
