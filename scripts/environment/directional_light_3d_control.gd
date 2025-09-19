extends DirectionalLight3D

func _enter_tree():
	GlobalPlayer.set_light_source(self)
