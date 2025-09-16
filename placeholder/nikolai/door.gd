extends MeshInstance3D

@onready var animation_door: AnimationPlayer = $"../../AnimationPlayer"

func door_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		animation_door.play("Door Open Push")
