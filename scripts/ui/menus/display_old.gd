extends Control

const RESOLUTION_DICTIONARY : Dictionary = {
	"2560 × 1440": Vector2(2560, 1440),
	"1920 × 1080": Vector2(1920, 1080),
	"1366 × 768": Vector2(1366, 768),
	"1280 × 720": Vector2(1260, 720),
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
@onready var selected_resolution = DisplayServer.screen_get_size()

func _ready():
	get_initial_settings()
	apply_resolution_scaling()
	if pause_menu == null:
		pause_menu = get_parent()
	#call_deferred("apply_manual_scaling")

func _input(event: InputEvent) -> void:
	if !visible:
		return
	if event.is_action_pressed("ui_up"):
		if !back.get_child(1).has_focus():
			return
		print("has focus")
		resolution_option.grab_focus()
	
func get_initial_settings():
	_on_resolution_selected(SettingsDataContainer.get_resolution_index())
	_on_window_mode_selected(SettingsDataContainer.get_window_mode_index())
	_on_language_item_selected(SettingsDataContainer.get_language_index())
	add_window_mode_items()
	add_resolution_items()
	add_language_items()
	center_window()

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
	print("selected resolution: ", index)
	SettingsSignalBus.emit_on_resolution_selected(index)
	var new_res = RESOLUTION_DICTIONARY.values()[index]
	DisplayServer.window_set_size(new_res)
	selected_resolution = new_res
	apply_resolution_scaling()
	center_window()

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
		2: #Borderless Window Mode
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)	
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
	center_window()

func center_window():
	var center_screen = DisplayServer.screen_get_position() + DisplayServer.screen_get_size()/2
	var window_size = get_window().get_size_with_decorations()
	get_window().set_position(center_screen - window_size/2)

func _on_language_item_selected(index: int) -> void:
	SettingsSignalBus.emit_on_language_selected(index)
	UIManager.update_lang(UIManager.LANGUAGES.keys()[index])

func _on_back_mouse_entered() -> void:
	pause_menu.toggle_button_selects(back, true)

func _on_back_mouse_exited() -> void:
	pause_menu.toggle_button_selects(back, false)

func apply_resolution_scaling():
	var screen_size = DisplayServer.screen_get_size()
	var target_resolution = Vector2(1920, 1080)
	var scale_factor = target_resolution.y / screen_size.y
	
	var root_window = get_tree().root as Window
	root_window.content_scale_factor = scale_factor

func apply_manual_scaling():
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	
	# Typen korrekt handhaben
	var screen_size = Vector2(DisplayServer.screen_get_size())
	var base_resolution = Vector2(1920, 1080)
	var scale_factor = screen_size / base_resolution
	
	scale_all_ui_nodes(get_tree().current_scene, scale_factor)

func scale_all_ui_nodes(node: Node, scale_factor: Vector2):
	if node is Control:
		node.scale = scale_factor
	
	for child in node.get_children():
		scale_all_ui_nodes(child, scale_factor)


func _on_back_pressed() -> void:
	pause_menu.display_back_pressed.emit();
