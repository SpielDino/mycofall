extends Node3D

@export var ray_position: RayCast3D

@onready var player: Node3D = GlobalPlayer.get_player()
@onready var world = GlobalPlayer.get_world()

var bullet_scene: PackedScene = preload("res://scenes/prefabs/weapons/player_arrow.tscn")

func spawn_bullet():
	var bullet_instance = bullet_scene.instantiate()
	var direction = player.get_child(0).get_child(0)
	bullet_instance.position = ray_position.global_position
	bullet_instance.transform.basis = direction.transform.basis
	world.add_child(bullet_instance)
