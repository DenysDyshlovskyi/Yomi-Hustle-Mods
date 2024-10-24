extends Node


const CL_VERSION = "4.0.0"

var _modZipFiles = []
var active_mods = []
var _savedObjects = []
var mods_w_depend = []
var mods_w_overwrites = []
var mods_w_missing_depend = {}
var active = false
var charLoaderModDetected = false
var charFolders = []

func _init():

	var file = File.new()
	if not file.file_exists("user://modded.json"):
		file.open("user://modded.json", File.WRITE)
		file.store_string(JSON.print({"modsEnabled": true}, "  "))
		file.close()
		
	file.open("user://modded.json", File.READ)
	var mod_options = JSON.parse(file.get_as_text()).result
	
	file.close()

	if not mod_options.modsEnabled:
		return 

	installScriptExtension("res://modloader/MLStateSounds.gd")

	var gameInstallDirectory = OS.get_executable_path().get_base_dir()
	if OS.get_name() == "OSX":
		gameInstallDirectory = gameInstallDirectory.get_base_dir().get_base_dir().get_base_dir()





	Steam.steamInit()
	active = true

	
	
	_loadMods()
	print("----------------mods------loaded--------------------")
	_initMods()
	print("----------------mods initialized--------------------")
	
	installScriptExtension("res://modloader/ModHashCheck.gd")
	call_deferred("append_hash")

func append_hash():

	var hashes = Network._get_hashes(ModLoader.active_mods)
	var h = ""
	for hash_ in hashes:
		h += hash_
	if SteamHustle.STARTED:
		if h != "":
			Global.VERSION += "-" + ("%10x" % hash(h)).strip_edges()
		else :
			Global.VERSION = Global.VERSION.split(" Modded")[0]

func _loadMods():
	var gameInstallDirectory = OS.get_executable_path().get_base_dir()
	if OS.get_name() == "OSX":
		gameInstallDirectory = gameInstallDirectory.get_base_dir().get_base_dir().get_base_dir()
	var modPathPrefix = gameInstallDirectory.plus_file("mods")
	_load_mods_in_folder(modPathPrefix)

	var dir2 = Directory.new()
	var _directories = []
	var workshop = SteamWorkshop.new()
	for item in Steam.getSubscribedItems():
		var info: Dictionary
		info = workshop.get_item_install_info(item)
		if info.ret:
			_load_mods_in_folder(info.folder, true)

func _load_mods_in_folder(modPathPrefix, zip_only = false):
	print("loading mods in folder: " + modPathPrefix)
	var dir = Directory.new()
	if dir.open(modPathPrefix) != OK:
		return 
	if dir.list_dir_begin() != OK:
		return 

	while true:
		var fileName = dir.get_next()
		if fileName == "":
			break
		if dir.current_is_dir():
			continue
		var modFSPath: String = modPathPrefix.plus_file(fileName)
		if zip_only and modFSPath.get_extension() != "zip":
			continue
		var modGlobalPath = ProjectSettings.globalize_path(modFSPath)
		if not ProjectSettings.load_resource_pack(modGlobalPath, true):
			continue
		_modZipFiles.append(modFSPath)

	dir.list_dir_end()



func _initMods():
	for modFSPath in _modZipFiles:
		var gdunzip = load("res://modloader/gdunzip/gdunzip.gd").new()
		gdunzip.load(modFSPath)
		var modHash = _hash_file(modFSPath)
		for modEntryPath in gdunzip.files:
			var modSubFolder = modEntryPath.rsplit("/")[0]
			var modEntryName = modEntryPath.get_file().to_lower()
			
			if modEntryName.begins_with("modmain") and modEntryName.ends_with(".gd"):
				
				var metaRes = _checkMetadata(modSubFolder, gdunzip.files, modEntryPath)
				if metaRes != null:
					var modInfo = [metaRes[0], modHash, metaRes[1]]
					if metaRes[1].name == "char_loader" and metaRes[1].id == "12345":
						charLoaderModDetected = true
						continue
					if modInfo[2].requires == [""]:
						modInfo[0] = ResourceLoader.load(modInfo[0])
						if modInfo[2].overwrites:
							mods_w_overwrites.append({"subfolder": modSubFolder, "priority": metaRes[1].priority})
						active_mods.append(modInfo)
					elif modInfo[2].requires != [""]:
						_dependencyCheck(modInfo, true, modSubFolder)
	for modInfo in mods_w_depend:
		_dependencyCheck(modInfo, false, modInfo[0])
	active_mods.sort_custom(self, "_compareScriptPriority")
	for item in active_mods:
		var scriptInstance = item[0].new(self)
		add_child(scriptInstance)
		print("Loaded " + item[2].friendly_name)
		item.remove(0)
	mods_w_overwrites.sort_custom(self, "_compareScriptPriority")
	var doesExist = Directory.new()
	for item in mods_w_overwrites:
		for character in Global.name_paths:
			if doesExist.file_exists(Global.name_paths.get(character)):
				_overwriteCharacterTexs(item.subfolder, character)

func _dependencyCheck(modInfo, first, modSubFolder):
	
	var missing_dependices = modInfo[2].requires.duplicate()
	missing_dependices.erase("char_loader")

	
	var dependices_loaded = false
	for item in modInfo[2].requires:
		item = item.strip_edges()

		if item.replace(" ", "") == "":
			modInfo[2].requires.erase(item)
			missing_dependices.erase(item)
		
		for mods in active_mods:
			if mods[2].name == item:
				
				missing_dependices.erase(item)

	
	if len(missing_dependices) == 0:
		dependices_loaded = true
	else :
		dependices_loaded = false
	
	if not dependices_loaded:
		if first:
			
			mods_w_depend.append(modInfo)
		elif not first:
			
			print(str(modInfo[2].friendly_name) + ": Missing Dependency: " + str(missing_dependices))
			mods_w_missing_depend[modInfo[2].friendly_name] = missing_dependices
	else :
		if modInfo[2].overwrites:
			mods_w_overwrites.append(modSubFolder)
			return 
			
		modInfo[0] = ResourceLoader.load(modInfo[0])
		active_mods.append(modInfo)
	


func _compareScriptPriority(a, b):
	var aPrio = a[2].priority
	var bPrio = b[2].priority
	if aPrio != bPrio:
		return aPrio < bPrio
	
	var aPath = a[0].resource_path
	var bPath = b[0].resource_path
	if aPath != bPath:
		return aPath < bPath
	return false

func installScriptExtension(childScriptPath: String):
	var childScript = ResourceLoader.load(childScriptPath)
	
	
	
	
	
	
	
	childScript.new()
	var parentScript = childScript.get_base_script()
	if parentScript == null:
		print("Missing dependencies")
	else :
		if parentScript.resource_path != "res://Network.gd" or childScript.resource_path == "res://modloader/ModHashCheck.gd":
			var parentScriptPath = parentScript.resource_path
			childScript.take_over_path(parentScriptPath)
		else :
			print("You can't access network!")

func appendNodeInScene(modifiedScene, nodeName: String = "", nodeParent = null, instancePath: String = "", isVisible: bool = true):
	var newNode
	if instancePath != "":
		newNode = load(instancePath).instance()
	else :
		newNode = Node.instance()
	if nodeName != "":
		newNode.name = nodeName
	if isVisible == false:
		newNode.visible = false
	if nodeParent != null:
		var tmpNode = modifiedScene.get_node(nodeParent)
		tmpNode.add_child(newNode)
		newNode.set_owner(modifiedScene)
	else :
		modifiedScene.add_child(newNode)
		newNode.set_owner(modifiedScene)

func saveScene(modifiedScene, scenePath: String):
	var packed_scene = PackedScene.new()
	packed_scene.pack(modifiedScene)
	packed_scene.take_over_path(scenePath)
	_savedObjects.append(packed_scene)
	
func _getTexsFromSheet(spritePath, columns, rows):
	pass

func _overwriteCharacterTexs(modFolderName, charName):
	
	var charImages = _get_all_files("res://" + modFolderName + "/Overwrites/" + charName, "png")
	var mediaSounds = _get_all_files("res://" + modFolderName + "/Overwrites/" + charName + "/Sounds/BaseSounds", "wav")
	var mediaStateSounds = _get_all_files("res://" + modFolderName + "/Overwrites/" + charName + "/Sounds/StateSounds", "wav")
	var charActionImages = _get_all_files("res://" + modFolderName + "/Overwrites/" + charName + "/Buttons", "png")
	mediaSounds.sort()
	mediaStateSounds.sort()
	
	
	var instCharTS = load(Global.name_paths.get(charName)).instance()
	var instCharAnim = instCharTS.get_node("Flip/Sprite")
	var instCharFrames = instCharAnim.get_sprite_frames()
	
	
	var instCharSounds = instCharTS.get_node("Sounds").get_children()
	var instCharStates = instCharTS.get_node("StateMachine").get_children()
	
	
	for media in charImages:
		var newFrameTex = textureGet(media)
		if media.split("/")[ - 2].to_lower() == "wait":
			instCharTS.character_portrait = newFrameTex
		if charName == "Cowboy" and media.split("/")[ - 3] == "ShootingArm":
			instCharAnim = instCharTS.get_node("Flip/ShootingArm")
			instCharFrames = instCharAnim.get_sprite_frames()
			instCharFrames.set_frame(media.split("/")[ - 2], int(media.get_file()), newFrameTex)
			instCharAnim = instCharTS.get_node("Flip/Sprite")
			instCharFrames = instCharAnim.get_sprite_frames()
		
		elif charName == "Wizard" and media.split("/")[ - 3] == "LiftoffAir":
			
			instCharAnim = instCharTS.get_node("Flip/LiftoffSprite")
			instCharFrames = instCharAnim.get_sprite_frames()
			instCharFrames.set_frame(media.split("/")[ - 2], int(media.get_file()), newFrameTex)
			instCharAnim = instCharTS.get_node("Flip/Sprite")
			instCharFrames = instCharAnim.get_sprite_frames()
		
		elif charName == "Robot" and media.split("/")[ - 3] == "ChainsawArm":
			instCharAnim = instCharTS.get_node("Flip/ChainsawArm")
			instCharFrames = instCharAnim.get_sprite_frames()
			instCharFrames.set_frame(media.split("/")[ - 2], int(media.get_file()), newFrameTex)
			instCharAnim = instCharTS.get_node("Flip/Sprite")
			instCharFrames = instCharAnim.get_sprite_frames()
			
		elif charName == "Robot" and media.split("/")[ - 3] == "DriveJumpSprite":
			instCharAnim = instCharTS.get_node("Flip/DriveJumpSprite")
			instCharFrames = instCharAnim.get_sprite_frames()
			instCharFrames.set_frame(media.split("/")[ - 2], int(media.get_file()), newFrameTex)
			instCharAnim = instCharTS.get_node("Flip/Sprite")
			instCharFrames = instCharAnim.get_sprite_frames()
		
		else :
			instCharFrames.set_frame(media.split("/")[ - 2], int(media.get_file()), newFrameTex)
			
	
	for charSound in instCharSounds:
		for media in mediaSounds:
			if media.get_file().split(".")[0] == charSound.name:
				var file = File.new()
				file.open(media, File.READ)
				var buffer = file.get_buffer(file.get_len())
				var stream = AudioStreamSample.new()
				stream.format = AudioStreamSample.FORMAT_16_BITS
				stream.data = buffer
				file.close()
				charSound.set_stream(stream)
				
				charSound.pitch_scale = 2
				
	
	for state in instCharStates:
		
		for media in mediaStateSounds:
			
			
			var media_name = media.get_file().trim_suffix("." + media.get_extension())
			if media_name.split("_")[0] == state.name:
				var file = File.new()
				file.open(media, File.READ)
				var buffer = file.get_buffer(file.get_len())
				var stream = AudioStreamSample.new()
				stream.format = AudioStreamSample.FORMAT_16_BITS
				stream.data = buffer
				file.close()
				
				if media_name.split("_")[ - 1] != "enter":
					
					state.sfx = stream
					state.enter_sfx = null
				else :
					
					state.enter_sfx = stream
				
				state.pitch_scale = 2
		
		if state.button_texture != null:
			for button in charActionImages:
				var buttonName = button.get_file().trim_suffix("." + button.get_extension())
				if buttonName == state.name:
					var newButtonTex = textureGet(button)
					state.button_texture = newButtonTex
			
	
	saveScene(instCharTS, Global.name_paths.get(charName))
	instCharTS.queue_free()

func _get_all_files(path: String, file_ext: = "", files: = [], full_path: = true):
	var dir = Directory.new()
	if dir.open(path) == OK:
		dir.list_dir_begin(true, true)
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				files = _get_all_files(dir.get_current_dir().plus_file(file_name), file_ext, files)
			else :
				if file_ext and file_name.get_extension() != file_ext:
					file_name = dir.get_next()
					continue
				if full_path:
					files.append(dir.get_current_dir().plus_file(file_name))
				else :
					files.append(file_name)
			file_name = dir.get_next()
	else :
		print("An error occurred when trying to access %s." % path)
	return files
		
func textureGet(imagePath):
	var image = Image.new()
	var err = image.load(imagePath)
	if err != OK:
		return 0
	var tex = ImageTexture.new()
	tex.create_from_image(image, 0)
	return tex
		
func _hash_file(path):
	var file = File.new()
	var modZIPHash = file.get_md5(path)
	return modZIPHash
	


func _checkMetadata(modSubFolder, zipFiles, modEntryPath):
	if modSubFolder + "/_metadata" in zipFiles:
		var modMetadataPath = "res://" + modSubFolder + "/_metadata"
		var metadata = _readMetadata(modMetadataPath)
		var check = _verifyMetadata(metadata)
		if not check == null:
			print("Metadata error: " + check)
			return null
		else :
			var modGlobalPath = "res://" + modEntryPath
			var modInfo = [modGlobalPath, metadata]
			_editMetaData(metadata, modMetadataPath)
			return modInfo
	else :
		print("No metadata in mod: " + modSubFolder)
		return null

func _editMetaData(metadata, modMetadataPath):
	metadata["id"] = "12345"
	var f = File.new()
	f.open(modMetadataPath, File.WRITE)
	f.store_string(JSON.print(metadata, "  ", true))
	f.close()

func _readMetadata(mdFSPath):
	var file = File.new()
	var metadata
	if not file.file_exists(mdFSPath):
		return null
	file.open(mdFSPath, File.READ)
	metadata = JSON.parse(file.get_as_text())
	if metadata.error != OK:
		return 
	file.close()
	return metadata.result

func _verifyMetadata(metadataVar):
	var mdString = JSON.print(metadataVar)
	var error: String = ""
	
	error = validate_json(mdString)
	if error: return "Invalid JSON data passed with message: " + error
	var schema = [
		"name", 
		"friendly_name", 
		"description", 
		"author", 
		"version", 
		"link", 
		"id", 
		"overwrites", 
		"requires", 
		"priority", 
	]
	
	if not metadataVar.has_all(schema):
		return "Metadata is missing fields"
	for key in metadataVar:
		if key == null:
			return key + " is empty"

func add_character_folder(path):
	if not (path in charFolders):
		charFolders.append(path)


func get_scripts(path):
	var scripts = []
	var dir = Directory.new()
	dir.open(path)
	
	if not dir.list_dir_begin() == OK:
		print("FAILED TO LOAD SCRIPTS")
		return 
	
	while true:
		var file = dir.get_next()
		if file == "":
			break
		elif not file.begins_with(".") and file.ends_with(".gd"):
			scripts.append(file)
			
	dir.list_dir_end()
	return scripts
