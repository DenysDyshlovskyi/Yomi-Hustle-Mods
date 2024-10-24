extends "res://ui/UILayer.gd"

var noSteam = false

func _process(delta):
	$"%VersionLabel".text = "version " + Global.VERSION

func _ready():
	var ver = - 1
	
	
	
	
	
	

func _on_steam_multiplayer_pressed():
	
	if not noSteam:
		._on_steam_multiplayer_pressed()
	else :
		OS.shell_open("https://cdn.discordapp.com/attachments/750542558614257697/1072636992984191088/image.png")
		$"%SteamMultiplayerButton".disabled = true
