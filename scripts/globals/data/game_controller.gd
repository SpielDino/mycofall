class_name GameController extends Node

signal all_queued_scenes_loaded

enum TransitionMode {AUTO, START, END_FLASH, NONE}
@export var world_3d: Node3D

@export var gui: Control;

var current_3d_scenes: Dictionary[String, Node3D];
var current_gui_scenes: Dictionary[String, Control];

var cached_3d_scenes: Dictionary[String, Node3D]

var all_queued_scenes_added: bool = false;

var tutorial_loaded: bool = false;
var one_loaded: bool = true;
var two_loaded: bool = false;
var three_loaded: bool = false;
var four_loaded: bool = false;
var boss_loaded: bool = false;

@onready var blend_screen = $GUI/Bending/BlendScreen

func _ready() -> void:
	GameManager.game_controller = self
	current_gui_scenes.get_or_add("title_screen", $GUI/TitleScreen)
	var tween = get_tree().create_tween().set_trans(Tween.TRANS_CUBIC)
	print(GlobalPlayer.get_player().get_child(0).global_position)
	tween.parallel().tween_property(blend_screen, "modulate:a", 0.0, 1.5)

func edit_scenes(
	add_scenes: Array[AddScene], 
	edited_scenes: Array[EditScene] = [],
	mode: int = TransitionMode.AUTO,
	freeze_player: bool = false
	) -> void:
		all_queued_scenes_added = false
		var m := _decide_mode(add_scenes, mode)  # AUTO → START or END_FLASH [docs]
		if m == TransitionMode.START:
			await _fade_to(1.0, 1.0)  # fade out first [docs]
			var res := await _load_batch(add_scenes)  # direct loads return immediately; threaded loads were none in START by default [docs]
			await _add_scenes(res, add_scenes)          # add to tree, place with global_transform as needed [docs]
			_delete_scenes(edited_scenes)

			await _fade_to(0.0, 1.5)     # fade back in [docs]
		elif m == TransitionMode.END_FLASH:
			var res := await _load_batch(add_scenes)  # load everything in background while UI animates [docs]
			await _fade_to(1.0, 1.5)  # quick fade-out [docs]
			await _add_scenes(res, add_scenes)              # swap in while black
			_delete_scenes(edited_scenes)
			await _fade_to(0.0, 1.5)    # quick fade-in [docs]

		elif m == TransitionMode.NONE:
			var res := await _load_batch(add_scenes)  # no fades at all [docs]
			await _add_scenes(res, add_scenes, true)
			_delete_scenes(edited_scenes)
		all_queued_scenes_loaded.emit()
		all_queued_scenes_added = true

				
			
func _delete_scenes(edited_scenes: Array[EditScene]):
		for scene in edited_scenes:
			var scene_name = scene.scene.split("/").get(scene.scene.split("/").size() - 1).split(".").get(0)
			if scene.type == EditScene.Type.DIMENSION_3:
				if !current_3d_scenes.has(scene_name):
					continue;
				var node = current_3d_scenes.get(scene_name);
				if scene.delete:
					node.queue_free()
					cached_3d_scenes.erase(scene_name)
					current_3d_scenes.erase(scene_name)
				elif scene.keep_running:
					node.visible = false;
				else:
					cached_3d_scenes.get_or_add(scene_name, node)
					current_3d_scenes.erase(scene_name)
					node.get_parent().remove_child(node)
			if scene.type == EditScene.Type.GUI:
				if !current_gui_scenes.has(scene_name):
					continue;
				var node = current_gui_scenes.get(scene_name)
				if scene.delete:
					node.queue_free()
					current_gui_scenes.erase(scene_name)
				elif scene.keep_running:
					node.visible = false;
				else:
					node.get_parent().remove_child(node)
					current_gui_scenes.erase(scene_name)
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

func _add_scenes(resources: Array, new_scenes: Array[AddScene], dynamic_loading: bool = false) -> void:
	for i in resources.size():
		var scene_name = new_scenes[i].scene.split("/").get(new_scenes[i].scene.split("/").size() - 1).split(".").get(0)
		var res: Resource = resources[i];
		if res == null:
			continue;
		if res is PackedScene:
			if new_scenes[i].type == new_scenes[i].Type.DIMENSION_3:
				var new: Node3D = (res as PackedScene).instantiate()
				if dynamic_loading:
					await add_children_smooth(new, world_3d, new_scenes[i].offset)
				else:
					world_3d.add_child(new)
				new.global_position = new_scenes[i].offset
				current_3d_scenes.get_or_add(scene_name, new);
			elif new_scenes[i].type == new_scenes[i].Type.GUI:
				var new: Control = (res as PackedScene).instantiate()
				gui.add_child(new)
				current_gui_scenes.get_or_add(scene_name, new);
		else:
			push_warning("Resource at index %d is not a PackedScene; skipping" % i)
			
func collect_scenes_levels(root) -> Array:
	var levels: Array = [];
	var first: Array = [];
	for child in root.get_children():
		root.remove_child(child)
		child.owner = null
		first.append({"node": child, "parent": root})
	if first.size() > 0:
		levels.append(first)
		
	var i: int = 0;
	var level_depth = 0
	while i < levels.size():
		if level_depth == 3:
			break
		var next_level: Array = []
		for pair in levels[i]:
			var n: Node = pair.node
			for child in n.get_children():
				n.remove_child(child)
				child.owner = null
				next_level.append({"node": child, "parent": n })
		if next_level.size() == 0:
			break
		levels.append(next_level)
		i += 1
		level_depth += 1
	return levels

func add_children_smooth(root: Node, target: Node, offset: Vector3, per_frame: int = 10) -> void:
	var levels = collect_scenes_levels(root)
	target.add_child(root)
	root.global_position = offset
	var lvl_depth = 0
	for lvl in levels:
		var node_count = 0
		for entry in lvl:
			if lvl_depth == 0:
				entry.node.process_mode = Node.PROCESS_MODE_DISABLED
			entry.parent.add_child(entry.node)
			node_count += 1
			if node_count == per_frame:
				node_count = 0
				await get_tree().process_frame
		lvl_depth += 1
	for child in root.get_children():
		child.process_mode = Node.PROCESS_MODE_INHERIT
	print("finished")
		
func instantiate_cached_3d_scene(scene: String) -> void:
	var scene_name = scene.split("/").get(scene.split("/").size() - 1).split(".").get(0)
	if !cached_3d_scenes.has(scene_name):
		push_warning("Scene does not exist in cached scenes: ", scene_name)
		return
	world_3d.add_child(cached_3d_scenes.get(scene_name))
