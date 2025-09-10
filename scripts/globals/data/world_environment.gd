extends WorldEnvironment

func _enter_tree():
	GlobalPlayer.set_world(self)
