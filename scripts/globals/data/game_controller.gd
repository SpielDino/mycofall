class_name GameController extends Node

@export var world_3d: Node3D

@export var gui: Control;

var current_3d_scene;
var current_gui_scene;

@onready var blend_screen = $GUI/Bending/BlendScreen

func _ready() -> void:
	GameManager.game_controller = self
	print(GameManager.game_controller)
	current_gui_scene = $GUI/TitleScreen
	var tween = get_tree().create_tween().set_trans(Tween.TRANS_CUBIC)
	tween.parallel().tween_property(blend_screen, "modulate:a", 0.0, 1.5)

func change_multiple_scenes(scenes_3d: Array[String], scenes_gui: Array[String], blend: bool = false, delete_3d: bool = true, delete_gui: bool = true, keep_running_3d: bool = false, keep_running_gui: bool = false):
	if blend:
		var tween = get_tree().create_tween().set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(blend_screen, "modulate:a", 1.0, 1.5)
		await get_tree().create_timer(3).timeout
	for scene in scenes_3d:
		await change_3d_scene(scene, delete_3d, keep_running_3d)
	for scene in scenes_gui:
		await change_gui_scene(scene, delete_gui, keep_running_gui)
	if blend:
		var tween = get_tree().create_tween().set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(blend_screen, "modulate:a", 0.0, 1.5)

func change_3d_scene(new_scene: String, delete: bool = true, keep_running: bool = false, blend: bool = false) -> bool:
	if blend:
		var tween = get_tree().create_tween().set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(blend_screen, "modulate:a", 1.0, 1.5)
		await get_tree().create_timer(3).timeout
	if current_3d_scene != null:
		if delete:
			current_3d_scene.queue_free();
		elif keep_running:
			current_3d_scene.visible = false;
		else:
			world_3d.remove_child(current_3d_scene);
	var new = load(new_scene).instantiate()
	gui.add_child(new)
	current_3d_scene = new;
	if blend:
		var tween = get_tree().create_tween().set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(blend_screen, "modulate:a", 0.0, 1.5)
	return true
	
func change_gui_scene(new_scene: String, delete: bool = true, keep_running: bool = false, blend: bool = false) -> bool:
	if blend:
		var tween = get_tree().create_tween().set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(blend_screen, "modulate:a", 1.0, 1.5)
		await get_tree().create_timer(1.5).timeout
	if current_gui_scene != null:
		if delete:
			current_gui_scene.queue_free();
		elif keep_running:
			current_gui_scene.visible = false;
		else:
			gui.remove_child(current_gui_scene);
	var new = load(new_scene).instantiate()
	gui.add_child(new)
	if blend:
		var tween = get_tree().create_tween().set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(blend_screen, "modulate:a", 0.0, 1.5)
	return true
