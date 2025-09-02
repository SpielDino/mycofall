extends Control

@onready var button_display: Button = $CenterContainer/OptionsMenu/ButtonsMargin/Buttons/Display;
@onready var button_controls: Button = $CenterContainer/OptionsMenu/ButtonsMargin/Buttons/Controls;
@onready var button_back: Button = $CenterContainer/OptionsMenu/ButtonsMargin/Buttons/Back;

@onready var pause_menu: Control = get_node_or_null("../../PauseMenu");
func _ready() -> void:
	if pause_menu == null:
		push_error("Couldn't load pause menu with node: PauseMenu")
		return
	pause_menu.controls_back_pressed.connect(_on_back_to_options_pressed)
	pause_menu.display_back_pressed.connect(_on_back_to_options_pressed)
	
func _on_controls_pressed() -> void:
	pause_menu.controls_pressed.emit()
	
func _on_back_to_options_pressed() -> void:
	button_display.grab_focus();
	
func _on_display_pressed() -> void:
	pause_menu.display_pressed.emit();
	
func _on_back_pressed() -> void:
	pause_menu.options_back_pressed.emit();
	SettingsSignalBus.emit_set_settings_dictionary(SettingsDataContainer.create_storage_dictionary())
