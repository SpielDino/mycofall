extends Area3D

signal hitting_with_shield

@export var reset_time: float = 0.3  # small cooldown window

@export_category("Sound")
@export_subgroup("Shield Bash")
@export var shield_bash_audio: AudioStreamPlayer3D

var hit_bodies := {}   # Dictionary or Set to remember which dummies/enemies are hit
var timer := 0.0
var heavy_dmg: int = 50
var is_heavy_dmg: bool = false
var upgrade_dmg: int = 0

func _physics_process(delta: float) -> void:
	if hit_bodies.size() > 0:
		timer += delta
		if timer > reset_time:
			hit_bodies.clear()
			timer = 0.0

func _on_body_entered(body: Node3D) -> void:
	get_upgrade_dmg()
	if body.is_in_group("Enemy"):
		hitting_enemy(body)
		hitting_with_shield.emit()
		shield_bash_audio.play()
	elif body.is_in_group("target_dummy"):
		hitting_target_dummy(body)
		hitting_with_shield.emit()
		shield_bash_audio.play()

func hitting_enemy(body: Node3D) -> void:
	# Only hit if we haven't already hit this body during the current swing
	if not hit_bodies.has(body):
		if GameManager.get_is_heavy_attacking():
			is_heavy_dmg = true
		else:
			is_heavy_dmg = false
		body.take_damage(heavy_dmg + upgrade_dmg, "Sword", is_heavy_dmg, 20)
		var dmg_position = body.get_node_or_null("DamageNumbersPosition")
		if dmg_position:
			DamageNumbers.display_number(heavy_dmg + upgrade_dmg, dmg_position.global_position)
		hit_bodies[body] = true   # mark this body as hit

func hitting_target_dummy(body: Node3D) -> void:
	if not hit_bodies.has(body):
		if GameManager.get_is_heavy_attacking():
			is_heavy_dmg = true
		else:
			is_heavy_dmg = false
		if body.get_node_or_null("AnimationPlayer"):
			body.play_animations(is_heavy_dmg)
		var dmg_position = body.get_node_or_null("DamageNumbersPosition")
		if dmg_position:
			DamageNumbers.display_number(heavy_dmg + upgrade_dmg, dmg_position.global_position)
		hit_bodies[body] = true

func get_upgrade_dmg():
	match GameManager.get_first_weapon_upgrade_level():
		2:
			upgrade_dmg = 10
		3:
			upgrade_dmg = 20
