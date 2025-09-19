extends Interactable

@export var animation_player: AnimationPlayer
@export var light: OmniLight3D
var open_chest: bool = false

func _on_interacted(body: Variant) -> void:
	if !open_chest:
		one_time_use = true
		open_chest = true
		animation_player.play("OberAction_001")
		await get_tree().create_timer(0.2).timeout
		light.visible = true
