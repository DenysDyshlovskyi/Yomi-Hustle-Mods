extends CharacterState

export var _c_CustomProjectileDynamic = 0

export (PackedScene) var ClackerTossScene
export var projPosX = 0
export var projPosY = 0

func _frame_10():
	host.spawn_object(ClackerTossScene, projPosX, projPosY)
