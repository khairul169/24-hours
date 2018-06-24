extends Spatial

func _ready():
	pass

func _input(event):
	if (event is InputEventKey):
		# Toggle fullscreen
		if (event.scancode == KEY_F11 && event.pressed):
			OS.window_fullscreen = !OS.window_fullscreen;
