extends Control

@onready var master_volume: HSlider = $soundMenuContainer/menuMargin/settingsMargin/settings/MarginContainer/VBoxContainer/master/HBoxContainer/HSlider
@onready var music_volume: HSlider = $soundMenuContainer/menuMargin/settingsMargin/settings/MarginContainer/VBoxContainer/music/HBoxContainer/HSlider
@onready var sfx_volume: HSlider = $soundMenuContainer/menuMargin/settingsMargin/settings/MarginContainer/VBoxContainer/sfx/HBoxContainer/HSlider
@onready var voice_volume: HSlider = $soundMenuContainer/menuMargin/settingsMargin/settings/MarginContainer/VBoxContainer/voice/HBoxContainer/HSlider

@onready var master_volume_display: Label = $soundMenuContainer/menuMargin/settingsMargin/settings/MarginContainer/VBoxContainer/master/HBoxContainer/Label
@onready var music_volume_display: Label = $soundMenuContainer/menuMargin/settingsMargin/settings/MarginContainer/VBoxContainer/music/HBoxContainer/Label
@onready var sfx_volume_display: Label = $soundMenuContainer/menuMargin/settingsMargin/settings/MarginContainer/VBoxContainer/sfx/HBoxContainer/Label
@onready var voice_volume_display: Label = $soundMenuContainer/menuMargin/settingsMargin/settings/MarginContainer/VBoxContainer/voice/HBoxContainer/Label

@onready var pause_menu: Control = get_node_or_null("../../PauseMenu");

func _ready() -> void:
	get_initial_settings()

func get_initial_settings():
	_on_master_changed(SettingsDataContainer.get_master_volume())
	_on_music_changed(SettingsDataContainer.get_music_volume())
	_on_sfx_changed(SettingsDataContainer.get_sfx_volume())
	_on_voice_changed(SettingsDataContainer.get_voice_volume())
	
func _on_master_changed(value: float) -> void:
	SettingsSignalBus.emit_on_master_volume_set(value)
	master_volume.value = value
	master_volume_display.text = "%d" % (value * 100)
	set_bus_value("Master", value)
	
func _on_music_changed(value: float) -> void:
	SettingsSignalBus.emit_on_music_volume_set(value)
	music_volume.value = value
	music_volume_display.text = "%d" % (value * 100)
	set_bus_value("Music", value)
	
func _on_sfx_changed(value: float) -> void:
	SettingsSignalBus.emit_on_sfx_volume_set(value)
	sfx_volume.value = value
	sfx_volume_display.text = "%d" % (value * 100)
	set_bus_value("SFX", value)
	
func _on_voice_changed(value: float) -> void:
	SettingsSignalBus.emit_on_voice_volume_set(value)
	voice_volume.value = value
	voice_volume_display.text = "%d" % (value * 100)
	set_bus_value("Voice", value)

func _on_back_pressed() -> void:
	pause_menu.sound_back_pressed.emit();

func set_bus_value(bus: String, value) -> void:
	if bus == "SFX":
		$"../AudioStreamPlayer2D".play()
	var bus_index =  AudioServer.get_bus_index(bus)
	AudioServer.set_bus_volume_linear(bus_index, value)
