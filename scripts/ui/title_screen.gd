extends Control

func _on_exit_game_pressed() -> void:
	get_tree().quit()


func _on_options_pressed() -> void:
	pass # Replace with function body.


func _on_start_pressed() -> void:
	var user_stats: AddScene = AddScene.new();
	user_stats.scene = "res://scenes/ui/stats/user_stats.tscn"
	user_stats.dynamic_loading = true;
	user_stats.type = AddScene.Type.GUI;
	
	var pause_menu: AddScene = AddScene.new();
	pause_menu.scene = "res://scenes/ui/menus/pause_menu.tscn"
	pause_menu.dynamic_loading = true;
	pause_menu.type = AddScene.Type.GUI;
	
	var intro: AddScene = AddScene.new();
	intro.scene = "res://scenes/production/game/intro/intro_sequence.tscn"
	intro.dynamic_loading = true;
	intro.type = AddScene.Type.DIMENSION_3;
	
	var title_screen: EditScene = EditScene.new();
	title_screen.scene = "res://scenes/ui/title_screen.tscn"
	title_screen.type = EditScene.Type.GUI
	
	GameManager.game_controller.edit_scenes([user_stats, pause_menu, intro], [title_screen], GameManager.game_controller.TransitionMode.END_FLASH)
