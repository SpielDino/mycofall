extends Node3D

func _ready() -> void:
	print(GlobalPlayer.get_player().get_child(0).position)
	GlobalPlayer.get_player().get_child(0).position = Vector3(0, 3.1, 7)
	GlobalPlayer.get_player().toggle_stamina.emit(true)
	GlobalPlayer.get_player().max_stamina = 200
	GlobalPlayer.get_player().stamina = 200
