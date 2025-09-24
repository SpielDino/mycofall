extends Node3D

@export var dmg: int = 50
@export var tick_rate: float = 1.0
@export var lifetime: float = 4.5

@export var magic_hit_audio: AudioStreamPlayer3D

var overlapping_bodies: Array = []
var active: bool = true
var upgrade_dmg: int = 0

var outer_ring_particle: GPUParticles3D
var pulse_ring_particle: GPUParticles3D
var random_magic_particles: GPUParticles3D

func _ready() -> void:
	outer_ring_particle = $OuterRing
	pulse_ring_particle = $PulseRings
	random_magic_particles = $RandomMagicParticles
	start_tick_dmg()

func start_tick_dmg():
	outer_ring_particle.restart()
	outer_ring_particle.emitting = true
	random_magic_particles.restart()
	random_magic_particles.emitting = true
	tick_dmg()
	await get_tree().create_timer(lifetime).timeout
	active = false
	queue_free()

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body not in overlapping_bodies:
		if body.is_in_group("Enemy") or body.is_in_group("target_dummy"):
			overlapping_bodies.append(body)
			apply_contact_dmg(body)

func _on_area_3d_body_exited(body: Node3D) -> void:
	if body in overlapping_bodies:
		overlapping_bodies.erase(body)

func tick_dmg():
	if not active:
		return
	await get_tree().create_timer(tick_rate * 0.75).timeout
	pulse_ring_particle.restart()
	pulse_ring_particle.emitting = true
	await get_tree().create_timer(tick_rate * 0.25).timeout
	apply_tick_dmg()
	tick_dmg()

func apply_tick_dmg():
	for body in overlapping_bodies:
		magic_hit_audio.play()
		get_upgrade_dmg()
		if body.is_in_group("Enemy"):
			body.take_damage(dmg + upgrade_dmg, "Staff")
			var dmg_position = body.get_node_or_null("DamageNumbersPosition")
			if dmg_position:
				DamageNumbers.display_number(dmg + upgrade_dmg, dmg_position.global_position)
		if body.is_in_group("target_dummy"):
			var dmg_position = body.get_node_or_null("DamageNumbersPosition")
			if dmg_position:
				DamageNumbers.display_number(dmg + upgrade_dmg, dmg_position.global_position)
			if body.get_node_or_null("AnimationPlayer"):
				body.play_animations(true)

func apply_contact_dmg(body):
	magic_hit_audio.play()
	get_upgrade_dmg()
	if body.is_in_group("Enemy"):
		body.take_damage(dmg + upgrade_dmg, "Staff", true, 1)
		var dmg_position = body.get_node_or_null("DamageNumbersPosition")
		if dmg_position:
			DamageNumbers.display_number(dmg + upgrade_dmg, dmg_position.global_position)
	if body.is_in_group("target_dummy"):
		var dmg_position = body.get_node_or_null("DamageNumbersPosition")
		if dmg_position:
			DamageNumbers.display_number(dmg + upgrade_dmg, dmg_position.global_position)
		if body.get_node_or_null("AnimationPlayer"):
			body.play_animations(true)

func get_upgrade_dmg():
	if GameManager.get_first_weapon_name() == "Staff":
		match GameManager.get_first_weapon_upgrade_level():
			2:
				upgrade_dmg = 10
			3:
				upgrade_dmg = 20
	elif GameManager.get_second_weapon_name() == "Staff":
		match GameManager.get_second_weapon_upgrade_level():
			2:
				upgrade_dmg = 10
			3:
				upgrade_dmg = 20
