extends Node

var player: Node3D 
var world: WorldEnvironment
var light_source: DirectionalLight3D

func set_player(player_in: Node3D):
	player = player_in

func get_player():
	return player

func set_world(check: WorldEnvironment):
	world = check
	
func get_world():
	return world

func get_light_source():
	return light_source

func set_light_source(check: DirectionalLight3D):
	light_source = check
