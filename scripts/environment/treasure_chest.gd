extends Interactable

@export var animation_player: AnimationPlayer
var open_chest: bool = false

func _on_interacted(body: Variant) -> void:
	if !open_chest:
		one_time_use = true
		open_chest = true
		animation_player.play("OberAction_001")
