extends Control

const RESOLUTION_DICTIONARY : Dictionary = {
	"2560 × 1440": Vector2(2560, 1440),
	"1920 × 1080": Vector2(1920, 1080),
	"1366 × 768": Vector2(1366, 768),
	"1280 × 720": Vector2(1280, 720),
}

const WINDOW_MODE_ARRAY : Array[String] = [
	"SETTING_FULL_SCREEN",
	"SETTING_WINDOWED",
	"SETTING_BORDERLESS_WINDOW",
]

@onready var resolution_option = $displayMenuContainer/menuMargin/settingsMargin/settings/MarginContainer/VBoxContainer/resolution/options
@onready var window_mode_option = $displayMenuContainer/menuMargin/settingsMargin/settings/MarginContainer/VBoxContainer/windowMode/options
@onready var lang_option = $displayMenuContainer/menuMargin/settingsMargin/settings/MarginContainer/VBoxContainer/language/options

@onready var back = $displayMenuContainer/menuMargin/NinePatchRect/buttonMargin/buttons/buttonsBack

@onready var pause_menu = get_node_or_null("../../pauseMenu")

@onready var selection_row: StyleBoxTexture = preload("res://assets/textures/ui_textures/menus/buttons/options_button/selected_stylebox.tres")
@onready var bg: StyleBoxTexture = preload("res://assets/textures/ui_textures/menus/buttons/options_button/popup_bg.tres")

func _ready():
	get_initial_settings()
	if pause_menu == null:
		pause_menu = get_parent()
	set_style_pop_up(resolution_option)
	set_style_pop_up(window_mode_option)
	set_style_pop_up(lang_option)

func _input(event: InputEvent) -> void:
	if !visible:
		return
	if event.is_action_pressed("ui_up"):
		if !back.get_child(1).has_focus():
			return
		resolution_option.grab_focus()
	
func get_initial_settings():
	_on_resolution_selected(SettingsDataContainer.get_resolution_index())
	_on_window_mode_selected(SettingsDataContainer.get_window_mode_index())
	_on_language_item_selected(SettingsDataContainer.get_language_index())
	add_window_mode_items()
	add_resolution_items()
	add_language_items()

func add_resolution_items() -> void:
	var index = 0
	for resolution_size_text in RESOLUTION_DICTIONARY:
		resolution_option.add_item(resolution_size_text)
		index += 1
	resolution_option.select(SettingsDataContainer.get_resolution_index())

func add_window_mode_items() -> void:
	for window_mode in WINDOW_MODE_ARRAY:
		window_mode_option.add_item(window_mode)
	window_mode_option.select(SettingsDataContainer.get_window_mode_index())

func add_language_items() -> void:
	var index = 0
	for lang in UIManager.LANGUAGES.values():
		lang_option.add_item(lang)
		if index == SettingsDataContainer.get_language_index():
			lang_option.select(index)
		index += 1
		
func _on_resolution_selected(index: int) -> void:
	SettingsSignalBus.emit_on_resolution_selected(index)

	var selected_res: Vector2i = RESOLUTION_DICTIONARY.values()[index]
	var screen = get_window().current_screen
	var screen_size: Vector2i = DisplayServer.screen_get_size(screen)

	if SettingsDataContainer.get_window_mode_index() == 2:
		apply_borderless_screen_filled()

	elif SettingsDataContainer.get_window_mode_index() == 1:
		apply_windowed_resolution(selected_res)

func _on_window_mode_selected(index: int) -> void:
	SettingsSignalBus.emit_on_window_mode_selected(index)
	match index:
		0: #Fullscreen
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)			
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
				# Basis-Auflösung definieren
			print("Fullscreen scaling aktiviert - UI wird unscharf skaliert")
		1: #Window Mode
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)	
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
			apply_windowed_resolution(RESOLUTION_DICTIONARY.values()[SettingsDataContainer.get_resolution_index()])	
		2: #Borderless Window Mode
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)	
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
			apply_borderless_screen_filled()

func _on_language_item_selected(index: int) -> void:
	SettingsSignalBus.emit_on_language_selected(index)
	UIManager.update_lang(UIManager.LANGUAGES.keys()[index])

func _on_back_mouse_entered() -> void:
	pause_menu.toggle_button_selects(back, true)

func _on_back_mouse_exited() -> void:
	pause_menu.toggle_button_selects(back, false)

func apply_windowed_resolution(new_client: Vector2i) -> void:
	var win := get_window()
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)

	var s := win.current_screen
	var usable := DisplayServer.screen_get_usable_rect(s)
	var current_client := win.size
	var current_with_deco := DisplayServer.window_get_size_with_decorations()
	var deco_extra := current_with_deco - current_client
	var desired_with_deco := new_client + deco_extra
	var clamped_with_deco := Vector2i(
		min(desired_with_deco.x, usable.size.x),
		min(desired_with_deco.y, usable.size.y)
	)
	win.size = clamped_with_deco
	var final_with_deco := DisplayServer.window_get_size_with_decorations()
	win.move_to_center()

func _on_back_pressed() -> void:
	pause_menu.display_back_pressed.emit();

func apply_borderless_screen_filled() -> void:
	var win := get_window()
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
	var s := win.current_screen
	var screen_size := DisplayServer.screen_get_size(s)
	DisplayServer.window_set_size(screen_size)
	win.move_to_center()
	
func set_style_pop_up(button: OptionButton) -> void:
	var pm: PopupMenu = button.get_popup()
	for i in pm.item_count:
		pm.add_theme_stylebox_override("panel", bg)
		pm.add_theme_stylebox_override("unchecked", selection_row)
		pm.add_theme_stylebox_override("hover", selection_row)
		pm.add_theme_constant_override("icon_max_width", 0)
		pm.add_theme_font_size_override("font_size", 30)
		pm.set_item_as_radio_checkable(i, false)
