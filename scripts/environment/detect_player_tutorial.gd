extends Area3D

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
				var intro: EditScene = EditScene.new();
				intro.scene = "res://scenes/production/game/intro/intro_sequence.tscn"
				intro.type = EditScene.Type.DIMENSION_3;
				GameManager.game_controller.tutorial_loaded = true
				GameManager.game_controller.one_loaded = true
				var two: AddScene = AddScene.new();
				two.scene = "res://scenes/production/game/area_one/area_one.tscn"
				two.dynamic_loading = false;
				two.type = AddScene.Type.DIMENSION_3;
				two.offset = Vector3(-34.5, 0.0, -178.0);
				var three: AddScene = AddScene.new();
				three.scene = "res://placeholder/leon/LeonTestScene.tscn"
				three.dynamic_loading = false;
				three.type = AddScene.Type.DIMENSION_3;
				three.offset = Vector3(65.0, 0.0, -314.0);
				var four: AddScene = AddScene.new();
				four.scene = "res://scenes/production/working_trees/Area_4.tscn"
				four.dynamic_loading = false;
				four.type = AddScene.Type.DIMENSION_3;
				four.offset = Vector3(-84.5, 0.0, -412);
				var boss: AddScene = AddScene.new();
				boss.scene = "res://scenes/prefabs/environment/boss_arena.tscn"
				boss.dynamic_loading = false;
				boss.type = AddScene.Type.DIMENSION_3;
				boss.offset = Vector3(-33, -4.415, -373);
				var one_unload: EditScene = EditScene.new();
				one_unload.scene = "res://scenes/prefabs/environment/rooms/level_rooms/combined_beginning_room.tscn"
				one_unload.delete = false
				one_unload.type = EditScene.Type.DIMENSION_3;
				var two_unload: EditScene = EditScene.new();
				two_unload.scene = "res://scenes/production/game/area_one/area_one.tscn"
				two_unload.delete = false
				two_unload.type = EditScene.Type.DIMENSION_3;
				GameManager.game_controller.three_loaded = false
				var three_unload: EditScene = EditScene.new();
				three_unload.scene = "res://placeholder/leon/LeonTestScene.tscn"
				three_unload.delete = false
				three_unload.type = EditScene.Type.DIMENSION_3;
				var four_unload: EditScene = EditScene.new();
				four_unload.scene = "res://scenes/production/working_trees/Area_4.tscn"
				four_unload.delete = false
				four_unload.type = EditScene.Type.DIMENSION_3;
				var boss_unload: EditScene = EditScene.new();
				boss_unload.scene = "res://scenes/prefabs/environment/boss_arena.tscn"
				boss_unload.delete = false
				boss_unload.type = EditScene.Type.DIMENSION_3;
				GameManager.game_controller.edit_scenes([tutorial, one], [intro], GameManager.game_controller.TransitionMode.START, true)

			"TutorialUnload":
				GameManager.game_controller.tutorial_loaded = false
				var tutorial: EditScene = EditScene.new();
				tutorial.scene = "res://scenes/prefabs/environment/rooms/level_rooms/training_room.tscn"
				tutorial.type = EditScene.Type.DIMENSION_3;
				GameManager.game_controller.edit_scenes([], [tutorial], GameManager.game_controller.TransitionMode.NONE)
				
			"OneLoad":
				if !GameManager.game_controller.one_loaded:
					var one: AddScene = AddScene.new();
					one.scene = "res://scenes/prefabs/environment/rooms/level_rooms/combined_beginning_room.tscn"
					one.dynamic_loading = false;
					one.type = AddScene.Type.DIMENSION_3;
					one.offset = Vector3(-35.0, 0.0, -99.9);
					GameManager.game_controller.one_loaded = true
					GameManager.game_controller.edit_scenes([one], [], GameManager.game_controller.TransitionMode.NONE)
				
			"OneUnload":
				GameManager.game_controller.one_loaded = false
				var one_unload: EditScene = EditScene.new();
				one_unload.scene = "res://scenes/prefabs/environment/rooms/level_rooms/combined_beginning_room.tscn"
				one_unload.delete = false
				one_unload.type = EditScene.Type.DIMENSION_3;
				GameManager.game_controller.edit_scenes([], [one_unload], GameManager.game_controller.TransitionMode.NONE)
			"TwoLoad":
				if !GameManager.game_controller.two_loaded:
					print("loading two!!")
					var two: AddScene = AddScene.new();
					two.scene = "res://scenes/production/game/area_one/area_one.tscn"
					two.dynamic_loading = false;
					two.type = AddScene.Type.DIMENSION_3;
					two.offset = Vector3(-34.5, 0.0, -178.0);
					GameManager.game_controller.two_loaded = true
					print(GameManager.game_controller.two_loaded)
					GameManager.game_controller.edit_scenes([two], [], GameManager.game_controller.TransitionMode.NONE)
					
			"TwoUnload":
				print("unloading two!")
				GameManager.game_controller.two_loaded = false
				var two_unload: EditScene = EditScene.new();
				two_unload.scene = "res://scenes/production/game/area_one/area_one.tscn"
				two_unload.delete = false
				two_unload.type = EditScene.Type.DIMENSION_3;
				GameManager.game_controller.edit_scenes([], [two_unload], GameManager.game_controller.TransitionMode.NONE)
			"ThreeLoad":
				if !GameManager.game_controller.three_loaded:
					var three: AddScene = AddScene.new();
					three.scene = "res://placeholder/leon/LeonTestScene.tscn"
					three.dynamic_loading = false;
					three.type = AddScene.Type.DIMENSION_3;
					three.offset = Vector3(65.0, 0.0, -314.0);
					GameManager.game_controller.three_loaded = true
					GameManager.game_controller.edit_scenes([three], [], GameManager.game_controller.TransitionMode.NONE)
			"ThreeUnload":
				if GameManager.game_controller.three_loaded:
					GameManager.game_controller.three_loaded = false
					var three: EditScene = EditScene.new();
					three.scene = "res://placeholder/leon/LeonTestScene.tscn"
					three.delete = false
					three.type = EditScene.Type.DIMENSION_3;
					GameManager.game_controller.edit_scenes([], [three], GameManager.game_controller.TransitionMode.NONE)
			"ThreeUnload2":
				if GameManager.game_controller.three_loaded:
					GameManager.game_controller.three_loaded = false
					var three: EditScene = EditScene.new();
					three.scene = "res://placeholder/leon/LeonTestScene.tscn"
					three.delete = false
					three.type = EditScene.Type.DIMENSION_3;
					GameManager.game_controller.edit_scenes([], [three], GameManager.game_controller.TransitionMode.NONE)
			"FourLoad":
				if !GameManager.game_controller.four_loaded:
					var four: AddScene = AddScene.new();
					four.scene = "res://scenes/production/working_trees/Area_4.tscn"
					four.dynamic_loading = false;
					four.type = AddScene.Type.DIMENSION_3;
					four.offset = Vector3(-84.5, 0.0, -412);
					GameManager.game_controller.four_loaded = true
					GameManager.game_controller.edit_scenes([four], [], GameManager.game_controller.TransitionMode.NONE)
			"FourUnload":
				GameManager.game_controller.four_loaded = false
				var four_unload: EditScene = EditScene.new();
				four_unload.scene = "res://scenes/production/working_trees/Area_4.tscn"
				four_unload.delete = false
				four_unload.type = EditScene.Type.DIMENSION_3;
				GameManager.game_controller.edit_scenes([], [four_unload], GameManager.game_controller.TransitionMode.NONE)
			"BossLoad":
				if !GameManager.game_controller.boss_loaded:
					var boss: AddScene = AddScene.new();
					boss.scene = "res://scenes/prefabs/environment/boss_arena.tscn"
					boss.dynamic_loading = false;
					boss.type = AddScene.Type.DIMENSION_3;
					boss.offset = Vector3(-33, -4.415, -373);
					GameManager.game_controller.boss_loaded = true
					GameManager.game_controller.edit_scenes([boss], [], GameManager.game_controller.TransitionMode.NONE)
			"BossUnload":
				GameManager.game_controller.boss_loaded = false
				var boss_unload: EditScene = EditScene.new();
				boss_unload.scene = "res://scenes/prefabs/environment/boss_arena.tscn"
				boss_unload.delete = false
				boss_unload.type = EditScene.Type.DIMENSION_3;
				GameManager.game_controller.edit_scenes([], [boss_unload], GameManager.game_controller.TransitionMode.NONE)
