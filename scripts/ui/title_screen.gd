extends Control

signal display_pressed;
signal controls_pressed;
signal sound_pressed;
signal display_back_pressed;
signal controls_back_pressed;
signal sound_back_pressed;
signal options_back_pressed;

@onready var title = $MarginContainer/TitleAnimation

@onready var options_menu: Control = $Options;
@onready var controls_menu: Control = $Controls;
@onready var display_menu: Control = $Display;
@onready var sound_menu: Control = $Sound;

@onready var buttons: VBoxContainer = $ButtonsMargin/Buttons
@onready var button_start: Button = $ButtonsMargin/Buttons/Start
@onready var button_options: Button = $ButtonsMargin/Buttons/Options
@onready var button_exit_game: Button = $ButtonsMargin/Buttons/ExitGame

@onready var label_start = $ButtonsMargin/Buttons/Start/RichTextLabel
@onready var label_options = $ButtonsMargin/Buttons/Options/RichTextLabel
@onready var label_exit_game = $ButtonsMargin/Buttons/ExitGame/RichTextLabel
@onready var options_anim: AnimatedSprite2D = $Options/CenterContainer/OptionsMenu/AnimatedSprite2D

func _ready():
	button_start.modulate.a = 0;
	button_options.modulate.a = 0;
	button_exit_game.modulate.a = 0;
	label_start.visible_ratio = 0;
	label_options.visible_ratio = 0;
	label_exit_game.visible_ratio = 0;
	connect_button_signals()
	show_labels(1)
	for button: Button in get_tree().get_nodes_in_group("rich_button"):
		button.mouse_entered.connect(_on_hover.bind(button.get_child(0)))
		button.mouse_exited.connect(_on_unhover.bind(button.get_child(0)))
		
func connect_button_signals() -> void:
	options_back_pressed.connect(_on_options_back_pressed);
	display_pressed.connect(_on_display_pressed);
	controls_pressed.connect(_on_controls_pressed);
	sound_pressed.connect(_on_sound_pressed);
	display_back_pressed.connect(_on_display_back_pressed);
	controls_back_pressed.connect(_on_controls_back_pressed);
	sound_back_pressed.connect(_on_sound_back_pressed);

func _on_exit_game_pressed() -> void:
	get_tree().quit()

func _on_start_pressed() -> void:
	var tween = get_tree().create_tween().set_trans(Tween.TRANS_CUBIC)
	show_labels(0)
	tween.parallel().tween_property(title, "modulate:a", 0.0, 1.0)
	tween.parallel().tween_property(buttons, "modulate:a", 0.0, 1.0)
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

func _on_display_pressed() -> void:
	options_menu.visible = false
	display_menu.visible = true

func _on_display_back_pressed() -> void:
	options_menu.visible = true
	display_menu.visible = false

func _on_controls_pressed() -> void:
	options_menu.visible = false
	controls_menu.visible = true

func _on_controls_back_pressed() -> void:
	options_menu.visible = true
	controls_menu.visible = false

func _on_sound_pressed() -> void:
	options_menu.visible = false
	sound_menu.visible = true

func _on_sound_back_pressed() -> void:
	options_menu.visible = true
	sound_menu.visible = false

func show_labels(target_modulate: int) -> void:
	var tween_labels: Tween = get_tree().create_tween().set_trans(Tween.TRANS_CUBIC)
	tween_labels.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween_labels.parallel().tween_property(button_start, "modulate:a", target_modulate, 0.5)
	tween_labels.parallel().tween_property(button_options, "modulate:a", target_modulate, 0.5)
	tween_labels.parallel().tween_property(button_exit_game, "modulate:a", target_modulate, 0.5)
	tween_labels.parallel().tween_property(label_start, "visible_ratio", target_modulate, 0.5);
	tween_labels.parallel().tween_property(label_options, "visible_ratio", target_modulate, 0.5);
	tween_labels.parallel().tween_property(label_exit_game, "visible_ratio", target_modulate, 0.5);

func _on_options_pressed() -> void:
	title.visible = false
	buttons.visible = false
	options_menu.visible = true
	show_labels(0)

func _on_options_back_pressed() -> void:
	options_menu.visible = false
	title.visible = true
	buttons.visible = true
	show_labels(1)
	button_start.grab_focus()

func _on_hover(label: RichTextLabel) -> void:
	# do something with the specific UI element
	label.add_theme_color_override("default_color", Color.WHITE)

func _on_unhover(label: RichTextLabel) -> void:
	label.add_theme_color_override("default_color", Color.BLACK)
