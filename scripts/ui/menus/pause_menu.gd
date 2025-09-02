extends Control

signal display_pressed;
signal controls_pressed;
signal display_back_pressed;
signal controls_back_pressed;
signal options_back_pressed;

@onready var pause_menu: PanelContainer = $CenterContainer/PauseMenu;
@onready var options_menu: Control = $Options;
@onready var controls_menu: Control = $Controls;
@onready var display_menu: Control = $Display;

@onready var button_resume: Button = $CenterContainer/PauseMenu/ButtonsMargin/Buttons/Resume;
@onready var button_options: Button = $CenterContainer/PauseMenu/ButtonsMargin/Buttons/Options;
@onready var button_exit_game: Button = $CenterContainer/PauseMenu/ButtonsMargin/Buttons/ExitGame;


func _ready() -> void:
	connect_button_signals()

func connect_button_signals() -> void:
	options_back_pressed.connect(_on_options_back_pressed);
	display_pressed.connect(_on_display_pressed);
	controls_pressed.connect(_on_controls_pressed);
	display_back_pressed.connect(_on_display_back_pressed);
	controls_back_pressed.connect(_on_controls_back_pressed);

func _on_options_back_pressed() -> void:
	options_menu.visible = false
	pause_menu.visible = true
	button_resume.grab_focus()

func _on_controls_back_pressed() -> void:
	options_menu.visible = true
	controls_menu.visible = false
#
func _on_display_pressed() -> void:
	print("display")
	options_menu.visible = false
	display_menu.visible = true

func _on_display_back_pressed() -> void:
	options_menu.visible = true
	display_menu.visible = false

func _on_controls_pressed() -> void:
	options_menu.visible = false
	controls_menu.visible = true

func _on_options_pressed() -> void:
	options_menu.visible = true
	pause_menu.visible = false
