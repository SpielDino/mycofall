extends CharacterBody3D

@export var damage: float = 10
@export var speed: float = 10
@export var trackingRadius: float = 5
@export_range(0,1) var trackingStrength: float = 0
@export var player: Node3D
@export var vel: Vector3 = Vector3(1,0,0)

var isTracking: bool = false
var trackingDelay: float = 0
var blockCostModifier: float = 0

func set_parameter(playerInput: Node3D, damageInput: float, speedInput: float, trackingRadiusInput: float, trackingStrengthInput: float, velInput: Vector3, lifetimeInput: float):
	player = playerInput
	damage = damageInput
	speed = speedInput
	get_child(1).get_child(0).scale = Vector3(trackingRadiusInput, trackingRadiusInput, trackingRadiusInput)
	trackingStrength = trackingStrengthInput
	vel = velInput * 10
	await get_tree().create_timer(lifetimeInput).timeout
	queue_free()

func set_tracking_delay(delay):
	trackingDelay = delay

func set_block_cost_modifier(value):
	blockCostModifier = value

func _physics_process(delta):
	move(delta)
	move_and_slide()

func move(delta):
	var tempTrackingStrength = trackingStrength/10
	if !isTracking:
		tempTrackingStrength = 0 
	var directionToPlayer = -Vector3(global_transform.origin.x - player.get_child(0).global_transform.origin.x, global_transform.origin.y - player.get_child(0).global_transform.origin.y, global_transform.origin.z - player.get_child(0).global_transform.origin.z).normalized()
	if trackingDelay <= 0:
		vel = (vel * (1 - tempTrackingStrength) + directionToPlayer * tempTrackingStrength).normalized()
	if trackingDelay > 0:
		trackingDelay -= delta
	velocity = vel * speed * delta * 50

func _on_area_3d_area_entered(area: Area3D) -> void:
	if area.is_in_group("Player"):
		isTracking = true

func _on_area_3d_area_exited(area: Area3D) -> void:
	if area.is_in_group("Player"):
		isTracking = false

func _on_hit_area_area_entered(area: Area3D) -> void:
	if area.is_in_group("Player"):
		player.take_damage(damage, self, true, blockCostModifier)
		queue_free()

func _on_hit_area_body_entered(body: Node3D) -> void:
	if !body.is_in_group("Enemy"):
		queue_free()
