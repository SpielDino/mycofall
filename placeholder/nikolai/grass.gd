@tool
extends MultiMeshInstance3D

@export var player: Node3D

func _process(delta: float) -> void:
	if material_override is ShaderMaterial:
		material_override.set_shader_parameter("player_position", player.get_child(0).global_position)
