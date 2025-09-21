extends Area3D

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		GameManager.game_controller.change_3d_scene("res://scenes/prefabs/environment/rooms/level_rooms/training_room.tscn", Vector3.ZERO, true, false, true)
