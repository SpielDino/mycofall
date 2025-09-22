extends Control

@onready var button_display: Button = $CenterContainer/OptionsMenu/ButtonsMargin/Buttons/Display;
@onready var button_controls: Button = $CenterContainer/OptionsMenu/ButtonsMargin/Buttons/Controls;
@onready var button_sound: Button = $CenterContainer/OptionsMenu/ButtonsMargin/Buttons/Audio
@onready var button_back: Button = $CenterContainer/OptionsMenu/ButtonsMargin/Buttons/Back;
@onready var label_display =  $CenterContainer/OptionsMenu/ButtonsMargin/Buttons/Display/Label
@onready var label_controls = $CenterContainer/OptionsMenu/ButtonsMargin/Buttons/Controls/Label
@onready var label_sound = $CenterContainer/OptionsMenu/ButtonsMargin/Buttons/Audio/Label
@onready var label_back = $CenterContainer/OptionsMenu/ButtonsMargin/Buttons/Back/Label
@onready var buttons = $CenterContainer/OptionsMenu/ButtonsMargin/Buttons

@onready var options_anim = $CenterContainer/OptionsMenu/AnimatedSprite2D
@onready var pause_menu: Control = get_parent();

func _ready() -> void:
	if pause_menu == null:
		pause_menu = get_node_or_null("../../TitleScreen")
		push_error("Couldn't load pause menu with node: PauseMenu")
		return
	self.visibility_changed.connect(_on_options_pressed)
	pause_menu.controls_back_pressed.connect(_on_back_to_options_pressed)
	pause_menu.display_back_pressed.connect(_on_back_to_options_pressed)
	label_display.visible_ratio = 0;
	label_controls.visible_ratio = 0;
	label_sound.visible_ratio = 0;
	label_back.visible_ratio = 0;
	
	for button: Button in get_tree().get_nodes_in_group("button_rich"):
		button.mouse_entered.connect(_on_hover.bind(button.get_child(0)))
		button.mouse_exited.connect(_on_unhover.bind(button.get_child(0)))

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("pause") && self.visible:
		_on_back_pressed()
		
func _on_options_pressed() -> void:
	if self.visible == true:
		buttons.visible = true
		options_anim.play("open")
		await options_anim.animation_finished
		show_labels(1)
	else:
		show_labels(0)

func _on_display_pressed() -> void:
	pause_menu.display_pressed.emit();

func _on_controls_pressed() -> void:
	pause_menu.controls_pressed.emit()

func _on_sound_pressed() -> void:
	pause_menu.sound_pressed.emit();

func _on_back_pressed() -> void:
	buttons.visible = false
	options_anim.play("close")
	#await options_anim.animation_finished
	pause_menu.options_back_pressed.emit();
	show_labels(0)
	SettingsSignalBus.emit_set_settings_dictionary(SettingsDataContainer.create_storage_dictionary())

func _on_back_to_options_pressed() -> void:
	button_display.grab_focus();
	
	
func show_labels(target_modulate: int) -> void:
	var tween_labels: Tween = get_tree().create_tween().set_trans(Tween.TRANS_CUBIC)
	tween_labels.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween_labels.parallel().tween_property(button_display, "modulate:a", target_modulate, 0.5)
	tween_labels.parallel().tween_property(button_controls, "modulate:a", target_modulate, 0.5)
	tween_labels.parallel().tween_property(button_back, "modulate:a", target_modulate, 0.5)
	tween_labels.parallel().tween_property(label_display, "visible_ratio", target_modulate, 0.5);
	tween_labels.parallel().tween_property(label_controls, "visible_ratio", target_modulate, 0.5);
	tween_labels.parallel().tween_property(label_sound, "visible_ratio", target_modulate, 0.5);
	tween_labels.parallel().tween_property(label_back, "visible_ratio", target_modulate, 0.5);

func _on_hover(label: Label) -> void:
	# do something with the specific UI element
	label.add_theme_color_override("font_color", Color.WHITE)

func _on_unhover(label: Label) -> void:
	label.add_theme_color_override("font_color", Color.BLACK)
