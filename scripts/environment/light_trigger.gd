extends Node3D

var toogle_check: bool = true

@onready var light_source: DirectionalLight3D = GlobalPlayer.get_light_source()

func _on_light_off_trigger_box_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player") and !toogle_check:
		light_source.visible = false
		toogle_check = true


func _on_light_on_trigger_box_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player") and toogle_check:
		toogle_check = false
		await get_tree().create_timer(0.3).timeout
		light_source.visible = true
