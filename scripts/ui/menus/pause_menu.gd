extends Control

signal display_pressed;
signal controls_pressed;
signal sound_pressed;
signal display_back_pressed;
signal controls_back_pressed;
signal sound_back_pressed;
signal options_back_pressed;

@onready var pause_menu: PanelContainer = $CenterContainer/PauseMenu;
@onready var options_menu: Control = $Options;
@onready var controls_menu: Control = $Controls;
@onready var display_menu: Control = $Display;
@onready var sound_menu: Control = $Sound;

@onready var buttons: VBoxContainer = $CenterContainer/PauseMenu/ButtonsMargin/Buttons
@onready var button_resume: Button = $CenterContainer/PauseMenu/ButtonsMargin/Buttons/Resume
@onready var button_options: Button = $CenterContainer/PauseMenu/ButtonsMargin/Buttons/Options
@onready var button_main_menu: Button = $CenterContainer/PauseMenu/ButtonsMargin/Buttons/MainMenu

@onready var label_resume = $CenterContainer/PauseMenu/ButtonsMargin/Buttons/Resume/RichTextLabel
@onready var label_options = $CenterContainer/PauseMenu/ButtonsMargin/Buttons/Options/RichTextLabel
@onready var label_main_menu = $CenterContainer/PauseMenu/ButtonsMargin/Buttons/MainMenu/RichTextLabel
@onready var pause_anim: AnimatedSprite2D = $CenterContainer/PauseMenu/AnimatedSprite2D
@onready var options_anim: AnimatedSprite2D = $Options/CenterContainer/OptionsMenu/AnimatedSprite2D

func _ready() -> void:
	self.modulate.a = 0
	pause_menu.visible = false
	button_resume.modulate.a = 0;
	button_options.modulate.a = 0;
	button_main_menu.modulate.a = 0;
	label_resume.visible_ratio = 0;
	label_options.visible_ratio = 0;
	label_main_menu.visible_ratio = 0;
	connect_button_signals()
	for button: Button in get_tree().get_nodes_in_group("rich_button"):
		button.mouse_entered.connect(_on_hover.bind(button.get_child(0)))
		button.mouse_exited.connect(_on_unhover.bind(button.get_child(0)))

func _input(event) -> void:
	if event.is_action_pressed("pause") && !pause_menu.visible && !pause_anim.is_playing():
		UIManager.toggle_menu.emit()
		get_tree().paused = true
		print("pause is not visible")
		buttons.visible = true
		var blend_in = get_tree().create_tween().set_trans(Tween.TRANS_CUBIC)
		blend_in.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		blend_in.tween_property(self, "modulate:a", 1, 0.5)
		print("puase visible")
		visible = true
		pause_menu.visible = true;
		pause_anim.play("open")
		await pause_anim.animation_finished
		show_labels(1)
	elif event.is_action_pressed("pause") && pause_menu.visible && !pause_anim.is_playing():
		_on_resume_pressed()
	

func show_labels(target_modulate: int) -> void:
	var tween_labels: Tween = get_tree().create_tween().set_trans(Tween.TRANS_CUBIC)
	tween_labels.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween_labels.parallel().tween_property(button_resume, "modulate:a", target_modulate, 0.5)
	tween_labels.parallel().tween_property(button_options, "modulate:a", target_modulate, 0.5)
	tween_labels.parallel().tween_property(button_main_menu, "modulate:a", target_modulate, 0.5)
	tween_labels.parallel().tween_property(label_resume, "visible_ratio", target_modulate, 0.5);
	tween_labels.parallel().tween_property(label_options, "visible_ratio", target_modulate, 0.5);
	tween_labels.parallel().tween_property(label_main_menu, "visible_ratio", target_modulate, 0.5);
	
func connect_button_signals() -> void:
	options_back_pressed.connect(_on_options_back_pressed);
	display_pressed.connect(_on_display_pressed);
	controls_pressed.connect(_on_controls_pressed);
	sound_pressed.connect(_on_sound_pressed);
	display_back_pressed.connect(_on_display_back_pressed);
	controls_back_pressed.connect(_on_controls_back_pressed);
	sound_back_pressed.connect(_on_sound_back_pressed);

func _on_resume_pressed() -> void:
	UIManager.toggle_menu.emit()
	var blend_out = get_tree().create_tween().set_trans(Tween.TRANS_CUBIC)
	buttons.visible = false
	show_labels(0)
	pause_anim.play("blend_out")
	blend_out.tween_property(self, "modulate:a", 0, 0.5)
	await pause_anim.animation_finished
	pause_menu.visible = false
	get_tree().paused = false

func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	GlobalPlayer.get_player().process_mode = Node.PROCESS_MODE_DISABLED
	var bus_index =  AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_linear(bus_index, 0.0)
	var title_screen: AddScene = AddScene.new();
	title_screen.scene = "res://scenes/ui/title_screen.tscn"
	title_screen.dynamic_loading = false
	title_screen.type = AddScene.Type.GUI
	var user_stats: EditScene = EditScene.new();
	user_stats.scene = "res://scenes/ui/stats/user_stats.tscn"
	user_stats.type = EditScene.Type.GUI
	var pause_menu: EditScene = EditScene.new();
	pause_menu.scene = "res://scenes/ui/menus/pause_menu.tscn"
	pause_menu.type = EditScene.Type.GUI
	var intro: EditScene = EditScene.new();
	intro.scene = "res://scenes/production/game/intro/intro_sequence.tscn"
	intro.type = EditScene.Type.DIMENSION_3
	await GameManager.game_controller.edit_scenes([title_screen], [user_stats, pause_menu, intro], GameManager.game_controller.TransitionMode.START)
	AudioServer.set_bus_volume_linear(bus_index, SettingsDataContainer.get_master_volume())
	
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

func _on_options_pressed() -> void:
	pause_menu.visible = false
	options_menu.visible = true
	pause_anim.visible = false
	show_labels(0)

func _on_options_back_pressed() -> void:
	options_menu.visible = false
	pause_menu.visible = true
	pause_anim.visible = true
	pause_anim.play_backwards("close")
	await pause_anim.animation_finished
	show_labels(1)
	button_resume.grab_focus()

func _on_hover(label: RichTextLabel) -> void:
	# do something with the specific UI element
	label.add_theme_color_override("default_color", Color.WHITE)

func _on_unhover(label: RichTextLabel) -> void:
	label.add_theme_color_override("default_color", Color.BLACK)

func play_animation(name: String) -> void:
	pause_anim.anim
