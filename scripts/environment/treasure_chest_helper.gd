extends Interactable

@export var actual_script: StaticBody3D
var open_chest: bool = false

func _on_interacted(body: Variant) -> void:
	if !open_chest:
		one_time_use = true
		open_chest = true
		actual_script.interact(owner)
