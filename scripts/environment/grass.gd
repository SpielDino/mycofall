extends MultiMeshInstance3D

@onready var player: Node3D = GlobalPlayer.get_player()

func _process(delta: float) -> void:
	if material_override is ShaderMaterial:
		material_override.set_shader_parameter("player_position", player.get_child(0).global_position)
