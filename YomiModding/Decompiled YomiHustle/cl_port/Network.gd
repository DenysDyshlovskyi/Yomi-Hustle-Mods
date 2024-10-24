extends "res://Network.gd"

var _Global = self


var default_chars = 0
var css_instance = null
var ogVersion = Global.VERSION
var isSteamGame = false
var steam_errorMsg = ""

var retro_P2P_doFix = false






var player1_hash_to_folder
var player2_hash_to_folder

var player1_chars = []
var player2_chars = []

var steam_oppChars = []

var normal_mods = []
var char_mods = []


var hash_to_folder = {}

var diff = ""

var steam_isHost = false

remotesync func register_player(new_player_name, id, mods, isSteam = false):
	
	if (typeof(mods) != TYPE_DICTIONARY):
		mods = {"version": mods, "active_mods": []}

	if (mods.has("normal_mods")):
		if not second_register:
			player1_hashes = mods.normal_mods
			player1_chars = mods.char_mods
			player1_hash_to_folder = mods.hash_to_folder
			
			second_register = true
		elif second_register:
			player2_hashes = mods.normal_mods
			player2_chars = mods.char_mods
			player2_hash_to_folder = mods.hash_to_folder
			
			if not _compare_checksum():
				update_diffList()
				emit_signal("game_error", "Can't connect, you both need to share every server-side mod that isn't a character.\nDifferences: " + diff)
				return 
	else :
		second_register = true
	if mods.version != Global.VERSION:
		emit_signal("game_error", "Mismatched game versions.\nYou: %s, Opponent: %s." % [Global.VERSION, mods.version])
		return 
	
	if (get_tree().get_network_unique_id() == id):
		network_id = id
	
	_Global.isSteamGame = false

	print("registering player: " + str(id))
	players[id] = new_player_name
	emit_signal("player_list_changed")

func update_diffList():
	var diffList = []
	var namesList = []
	diff = ""
	var allHashes = player1_hashes + player2_hashes
	for h in allHashes:
		if ( not (h in player1_hashes) or not (h in player2_hashes)):
			diffList.append(h)

			var modName
			if (player1_hash_to_folder.has(h)):
				modName = player1_hash_to_folder[h]
			else :
				modName = player2_hash_to_folder[h]
			if not (modName in namesList):
				namesList.append(modName)
			else :
				namesList[namesList.find(modName)] += " (diff. versions)"

	for i in len(namesList):
		var m = namesList[i]
		if i > 0:
			diff += ", "

		diff += m.replace("res://", "")





	



remote func player_connected_relay():
	rpc_("register_player", [player_name, get_tree().get_network_unique_id(), {"active_mods": ModLoader.active_mods, "normal_mods": normal_mods, "hash_to_folder": hash_to_folder, "char_mods": char_mods, "version": Global.VERSION}])

func player_connected(id):
	if direct_connect:
		rpc_("register_player", [player_name, id, {"active_mods": ModLoader.active_mods, "normal_mods": normal_mods, "hash_to_folder": hash_to_folder, "char_mods": char_mods, "version": Global.VERSION}])

func host_game_direct(new_player_name, port):
	_reset()
	player_name = new_player_name
	peer = NetworkedMultiplayerENet.new()
	peer.create_server(int(port), MAX_PEERS)
	get_tree().set_network_peer(peer)
	multiplayer_active = true
	direct_connect = true
	multiplayer_host = true
	rpc_("register_player", [new_player_name, get_tree().get_network_unique_id(), {"active_mods": ModLoader.active_mods, "normal_mods": normal_mods, "hash_to_folder": hash_to_folder, "char_mods": char_mods, "version": Global.VERSION}])


func join_game_direct(ip, port, new_player_name):
	_reset()
	player_name = new_player_name
	peer = NetworkedMultiplayerENet.new()
	peer.create_client(ip, int(port))
	multiplayer_active = true
	direct_connect = true
	multiplayer_host = false
	get_tree().set_network_peer(peer)


func _compare_checksum():
	player1_hashes.sort()
	player2_hashes.sort()

	return player1_hashes == player2_hashes


remotesync func go_button_activate():
	do_button_activate()


remotesync func go_button_pressed():
	do_button_pressed()


func do_button_activate():
	if multiplayer_host:
		var goBtt = _Global.css_instance.get_node("GoButton")
		if not goBtt.visible:
			goBtt.show()
			_Global.css_instance.enable_online_go = true
		else :
			goBtt.disabled = false

func do_button_pressed():
	if not multiplayer_host:
		_Global.css_instance.buffer_go = true

remotesync func character_list(chars):
	steam_oppChars = chars
