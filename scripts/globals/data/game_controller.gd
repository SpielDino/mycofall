class_name GameController extends Node

enum TransitionMode {AUTO, START, END_FLASH, NONE}
@export var world_3d: Node3D

@export var gui: Control;

var current_3d_scenes: Dictionary[String, Node3D];
var current_gui_scenes: Dictionary[String, Control];

var cached_3d_scenes: Dictionary[String, Node3D]

@onready var blend_screen = $GUI/Bending/BlendScreen

func _ready() -> void:
	GameManager.game_controller = self
	current_gui_scenes.get_or_add("title_screen", $GUI/TitleScreen)
	var tween = get_tree().create_tween().set_trans(Tween.TRANS_CUBIC)
	tween.parallel().tween_property(blend_screen, "modulate:a", 0.0, 1.5)

func edit_scenes(
	add_scenes: Array[AddScene], 
	edit_scenes: Array[EditScene] = [],
	mode: int = TransitionMode.AUTO,
	freeze_player: bool = false
	) -> void:
		var m := _decide_mode(add_scenes, mode)  # AUTO → START or END_FLASH [docs]
		if m == TransitionMode.START:
			await _fade_to(1.0, 1.0)  # fade out first [docs]
			#if freeze_player:
				#GlobalPlayer.get_player().process_mode = Node.PROCESS_MODE_DISABLED
			var res := await _load_batch(add_scenes)  # direct loads return immediately; threaded loads were none in START by default [docs]
			_add_scenes(res, add_scenes)          # add to tree, place with global_transform as needed [docs]
			_delete_scenes(edit_scenes)
			print(GlobalPlayer.get_player().get_child(0).global_position)
			GlobalPlayer.get_player().get_child(0).global_position = Vector3(0, 3.1, 7)
			#GlobalPlayer.get_player().process_mode = Node.PROCESS_MODE_INHERIT

			await _fade_to(0.0, 1.5)     # fade back in [docs]
		elif m == TransitionMode.END_FLASH:
			var res := await _load_batch(add_scenes)  # load everything in background while UI animates [docs]
			await _fade_to(1.0, 1.5)  # quick fade-out [docs]
			_add_scenes(res, add_scenes)              # swap in while black
			_delete_scenes(edit_scenes)
			await _fade_to(0.0, 1.5)    # quick fade-in [docs]

		elif m == TransitionMode.NONE:
			var res := await _load_batch(add_scenes)  # no fades at all [docs]
			_add_scenes(res, add_scenes)
			_delete_scenes(edit_scenes)

				
			
func _delete_scenes(edit_scenes: Array[EditScene]):
		for scene in edit_scenes:
			var scene_name = scene.scene.split("/").get(scene.scene.split("/").size() - 1).split(".").get(0)
			if scene.type == EditScene.Type.DIMENSION_3:
				if !current_3d_scenes.has(scene_name):
					continue;
				var node = current_3d_scenes.get(scene_name);
				if scene.delete:
					node.queue_free()
				elif scene.keep_running:
					node.visible = false;
				else:
					cached_3d_scenes.get_or_add(scene_name, node)
					node.get_parent().remove_child(node)
			if scene.type == EditScene.Type.GUI:
				if !current_gui_scenes.has(scene_name):
					continue;
				var node = current_gui_scenes.get(scene_name)
				if scene.delete:
					node.queue_free()
				elif scene.keep_running:
					node.visible = false;
				else:
					node.get_parent().remove_child(node)
func _decide_mode(items: Array[AddScene], mode: int = -1) -> int:
	if mode != TransitionMode.AUTO:
		return mode
	var any_dynamic := false
	for item in items:
		if item.dynamic_loading:
			any_dynamic = true; break
	return TransitionMode.END_FLASH if any_dynamic else TransitionMode.START

func _load_batch(items: Array[AddScene]) -> Array:
	var out: Array = [];
	out.resize(items.size());
	var in_flight: int = 0;
	
	for i in items.size():
		var item: AddScene = items[i];
		if item.dynamic_loading:
			var err = ResourceLoader.load_threaded_request(item.scene)
			in_flight += 1;
		else:
			out[i] = load(item.scene)
	
	var progress: Array = [];
	
	while in_flight > 0:
		var done: int = 0;
		for i in items.size():
			if out[i] != null:
				continue;
			var status = ResourceLoader.load_threaded_get_status(items[i].scene, progress)
			if status == ResourceLoader.THREAD_LOAD_LOADED:
				out[i] = ResourceLoader.load_threaded_get(items[i].scene);
				done += 1;
			elif status == ResourceLoader.THREAD_LOAD_FAILED:
				push_error("Failed to load: %s, loading failed" % items[i].scene)
				out[i] = null; done += 1
			elif status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
				push_error("Failed to load: %s, invalid resource" % items[i].scene)
				out[i] = null; done += 1
		if done == 0:
			await get_tree().process_frame  # yield while anim plays [web:624]
		in_flight = 0
		for i in items.size():
			if out[i] == null: 
				in_flight += 1
	return out

func _fade_to(a: float, dur: float) -> void:
	var t := get_tree().create_tween().set_trans(Tween.TRANS_CUBIC)
	t.tween_property(blend_screen, "modulate:a", a, dur)
	await t.finished   # wait for fade step to complete [web:625][web:629]

func _add_scenes(resources: Array, new_scenes: Array[AddScene]) -> void:
	for i in resources.size():
		var scene_name = new_scenes[i].scene.split("/").get(new_scenes[i].scene.split("/").size() - 1).split(".").get(0)
		var res: Resource = resources[i];
		if res == null:
			continue;
		if res is PackedScene:
			if new_scenes[i].type == new_scenes[i].Type.DIMENSION_3:
				var new: Node3D = (res as PackedScene).instantiate()
				world_3d.add_child(new)
				new.global_position = new_scenes[i].offset
				current_3d_scenes.get_or_add(scene_name, new);
			elif new_scenes[i].type == new_scenes[i].Type.GUI:
				var new: Control = (res as PackedScene).instantiate()
				gui.add_child(new)
				current_gui_scenes.get_or_add(scene_name, new);
		else:
			push_warning("Resource at index %d is not a PackedScene; skipping" % i)

func instantiate_cached_3d_scene(scene: String) -> void:
	var scene_name = scene.split("/").get(scene.split("/").size() - 1).split(".").get(0)
	if !cached_3d_scenes.has(scene_name):
		push_warning("Scene does not exist in cached scenes: ", scene_name)
		return
	world_3d.add_child(cached_3d_scenes.get(scene_name))
