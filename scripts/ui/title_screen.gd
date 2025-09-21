extends Control

func _on_exit_game_pressed() -> void:
	get_tree().quit()


func _on_options_pressed() -> void:
	pass # Replace with function body.


func _on_start_pressed() -> void:
	GameManager.game_controller.change_multiple_scenes(["res://scenes/production/game/intro/intro_sequence.tscn"], ["res://scenes/ui/stats/user_stats.tscn", "res://scenes/ui/menus/pause_menu.tscn"], true)
