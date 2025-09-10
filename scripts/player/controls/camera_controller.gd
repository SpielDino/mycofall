extends Node3D

var player: Node3D
var speed: float
var camera_target: Node3D

func _ready():
	player = GlobalPlayer.get_player()
	speed = player.camera_follow_speed
	camera_target = player.get_child(0).get_child(1).get_child(0)
	#print(player)
	#print(speed)
	#print(camera_target)
	
func _physics_process(delta):
	move_camera_to_player()
	
func move_camera_to_player():
	var t_origin = camera_target.global_transform.origin - player.global_transform.origin
	var s_origin = self.transform.origin
	transform.origin = Vector3(lerp(s_origin.x, t_origin.x, speed), lerp(s_origin.y, t_origin.y, speed), lerp(s_origin.z, t_origin.z, speed))


func _on_stamina_timer_timeout() -> void:
	pass # Replace with function body.
