extends Interactable

@export var animation_player: AnimationPlayer

@export var text_position: Node3D

@export var rounded_rock_big: Node3D
@export var rounded_rock_middle: Node3D
@export var rounded_rock_small: Node3D
@export var dead_tree_left: Node3D
@export var dead_tree_right: Node3D
@export var invisible_collider: StaticBody3D

func _on_interacted(body: Variant) -> void:
	if GameManager.get_boss_puzzle():
		if text_position:
			DamageNumbers.display_text(tr("INFO_SOLVED"), text_position.global_position, 5)
			var tween = get_tree().create_tween().set_trans(Tween.TRANS_CUBIC);
			tween.parallel().tween_property(rounded_rock_small, "global_rotation_degrees", Vector3(0, -130, 0), 3)
			tween.parallel().tween_property(rounded_rock_middle, "global_rotation_degrees", Vector3(0, -130, 0), 4)
			tween.parallel().tween_property(rounded_rock_big, "global_rotation_degrees", Vector3(0, -130, 0), 5)
			tween.parallel().tween_property(dead_tree_left, "global_position", Vector3(dead_tree_left.global_position.x, -0.5, dead_tree_left.global_position.z), 5)
			tween.parallel().tween_property(dead_tree_right, "global_position", Vector3(dead_tree_right.global_position.x, -0.5, dead_tree_right.global_position.z), 5)
			invisible_collider.queue_free()
	else:
		if text_position:
			DamageNumbers.display_text(tr("INFO_CANT_SOLVE"), text_position.global_position, 5)
		
