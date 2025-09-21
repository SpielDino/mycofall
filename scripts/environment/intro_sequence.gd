extends Node3D

func _ready() -> void:
	GlobalPlayer.get_player().process_mode = Node.PROCESS_MODE_INHERIT
