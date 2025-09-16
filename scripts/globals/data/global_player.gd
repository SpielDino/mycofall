extends Node

var player: Node3D 
var world: WorldEnvironment

func set_player(player_in: Node3D):
	player = player_in

func get_player():
	return player

func set_world(check: WorldEnvironment):
	world = check
	
func get_world():
	return world
