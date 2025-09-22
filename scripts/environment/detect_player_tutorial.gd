extends Area3D

var one_loaded: bool = false;
var two_loaded: bool = false;
var three_loaded: bool = false;
var four_loaded: bool = false;
var boss_loaded: bool = false;

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		match self.name:
			"TutorialLoad":
				var tutorial: AddScene = AddScene.new();
				tutorial.scene = "res://scenes/prefabs/environment/rooms/level_rooms/training_room.tscn"
				tutorial.dynamic_loading = false;
				tutorial.type = AddScene.Type.DIMENSION_3;
				var one: AddScene = AddScene.new();
				one.scene = "res://scenes/prefabs/environment/rooms/level_rooms/combined_beginning_room.tscn"
				one.dynamic_loading = false;
				one.type = AddScene.Type.DIMENSION_3;
				one.offset = Vector3(-35.0, 0.0, -99.9);
				var two: AddScene = AddScene.new();
				two.scene = "res://scenes/production/game/area_one/area_one.tscn"
				two.dynamic_loading = true;
				two.type = AddScene.Type.DIMENSION_3;
				two.offset = Vector3(-34.5, 0.0, -178)
				two_loaded = true
				var three: AddScene = AddScene.new();
				three.scene = "res://placeholder/leon/LeonTestScene.tscn"
				three.dynamic_loading = true;
				three.type = AddScene.Type.DIMENSION_3;
				three.offset = Vector3(65, 0.0, -314)
				three_loaded = true
				#var four: AddScene = AddScene.new();
				#four.scene = "res://scenes/production/working_trees/Area_4.tscn"
				#four.dynamic_loading = true;
				#four.type = AddScene.Type.DIMENSION_3;
				#four.offset = Vector3(-84.5, 0.0, -412)
				#four_loaded = true
				var boss: AddScene = AddScene.new();
				boss.scene = "res://scenes/prefabs/environment/boss_arena.tscn"
				boss.dynamic_loading = true;
				boss.type = AddScene.Type.DIMENSION_3;
				boss.offset = Vector3(-33, -4.415, -373)
				boss_loaded = true
				var intro: EditScene = EditScene.new();
				intro.scene = "res://scenes/production/game/intro/intro_sequence.tscn"
				intro.type = EditScene.Type.DIMENSION_3;
				var one_unload: EditScene = EditScene.new();
				one_unload.scene = "res://scenes/prefabs/environment/rooms/level_rooms/combined_beginning_room.tscn"
				one_unload.delete = false
				one_unload.type = EditScene.Type.DIMENSION_3;
				var two_unload: EditScene = EditScene.new();
				two_unload.scene = "res://scenes/production/game/area_one/area_one.tscn"
				two_unload.delete = false
				two_unload.type = EditScene.Type.DIMENSION_3;
				var three_unload: EditScene = EditScene.new();
				three_unload.scene = "res://placeholder/leon/LeonTestScene.tscn"
				three_unload.delete = false
				three_unload.type = EditScene.Type.DIMENSION_3;
				#var four_unload: EditScene = EditScene.new();
				#four_unload.scene = "res://scenes/production/working_trees/Area_4.tscn"
				#four_unload.delete = false
				#four_unload.type = EditScene.Type.DIMENSION_3;
				var boss_unload: EditScene = EditScene.new();
				boss_unload.scene = "res://scenes/prefabs/environment/boss_arena.tscn"
				boss_unload.delete = false
				boss_unload.type = EditScene.Type.DIMENSION_3;
				GameManager.game_controller.edit_scenes([tutorial, one, two, three, boss], [intro, two_unload, three_unload, boss_unload], GameManager.game_controller.TransitionMode.START, true)
				await get_tree().create_timer(1.5).timeout
				GlobalPlayer.get_player().toggle_stamina.emit(true)
				GlobalPlayer.get_player().max_stamina = 200
				GlobalPlayer.get_player().stamina = 200
			"TutorialUnload":
				var tutorial: EditScene = EditScene.new();
				tutorial.scene = "res://scenes/prefabs/environment/rooms/level_rooms/training_room.tscn"
				tutorial.type = EditScene.Type.DIMENSION_3;
				GameManager.game_controller.edit_scenes([], [tutorial], GameManager.game_controller.TransitionMode.NONE)
			"OneLoad":
				if !one_loaded:
					one_loaded = true
					GameManager.game_controller.instantiate_cached_3d_scene("res://scenes/prefabs/environment/rooms/level_rooms/combined_beginning_room.tscn")
				
			"OneUnload":
				one_loaded = false
				var one_unload: EditScene = EditScene.new();
				one_unload.scene = "res://scenes/prefabs/environment/rooms/level_rooms/combined_beginning_room.tscn"
				one_unload.delete = false
				one_unload.type = EditScene.Type.DIMENSION_3;
				GameManager.game_controller.edit_scenes([], [one_unload], GameManager.game_controller.TransitionMode.NONE)
			"TwoLoad":
				if !two_loaded:
					two_loaded = false
					GameManager.game_controller.instantiate_cached_3d_scene("res://scenes/production/game/area_one/area_one.tscn")
			"TwoUnload":
				two_loaded = false
				var two_unload: EditScene = EditScene.new();
				two_unload.scene = "res://scenes/production/game/area_one/area_one.tscn"
				two_unload.delete = false
				two_unload.type = EditScene.Type.DIMENSION_3;
				GameManager.game_controller.edit_scenes([], [two_unload], GameManager.game_controller.TransitionMode.NONE)
			"ThreeLoad":
				if !three_loaded:
					three_loaded = true
					GameManager.game_controller.instantiate_cached_3d_scene("res://placeholder/leon/LeonTestScene.tscn")
			"ThreeUnload":
				three_loaded = false
				var three: EditScene = EditScene.new();
				three.scene = "res://placeholder/leon/LeonTestScene.tscn"
				three.delete = false
				three.type = EditScene.Type.DIMENSION_3;
				GameManager.game_controller.edit_scenes([], [three], GameManager.game_controller.TransitionMode.NONE)
			"FourLoad":
				if !four_loaded:
					four_loaded = true
					GameManager.game_controller.instantiate_cached_3d_scene("res://scenes/production/working_trees/Area_4.tscn")
			"FourUnload":
				four_loaded = false
				var four_unload: EditScene = EditScene.new();
				four_unload.scene = "res://placeholder/leon/LeonTestScene.tscn"
				four_unload.delete = false
				four_unload.type = EditScene.Type.DIMENSION_3;
				GameManager.game_controller.edit_scenes([], [four_unload], GameManager.game_controller.TransitionMode.NONE)
			"BossLoad":
				if !boss_loaded:
					boss_loaded = true
					GameManager.game_controller.instantiate_cached_3d_scene("res://scenes/prefabs/environment/boss_arena.tscn")
			"BossUnload":
				boss_loaded = false
				var boss_unload: EditScene = EditScene.new();
				boss_unload.scene = "res://scenes/prefabs/environment/boss_arena.tscn"
				boss_unload.delete = false
				boss_unload.type = EditScene.Type.DIMENSION_3;
				GameManager.game_controller.edit_scenes([], [boss_unload], GameManager.game_controller.TransitionMode.NONE)
