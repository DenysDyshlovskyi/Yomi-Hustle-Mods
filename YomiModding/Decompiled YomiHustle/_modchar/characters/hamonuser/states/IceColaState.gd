extends CharacterState

export var _c_CustomProjectileDynamic = 0

export (PackedScene) var IceColaProj
export var projPosX = 0
export var projPosY = 0

func _frame_4():
	host.spawn_object(IceColaProj, projPosX, projPosY)
