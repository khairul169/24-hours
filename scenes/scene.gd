extends Node

# Game variables
var game_time = 0.0;
var real_time = 0.0;
var timecycle_ratio = 0.0;

func _input(event):
	if (event is InputEventKey):
		# Toggle fullscreen
		if (event.scancode == KEY_F11 && event.pressed):
			OS.window_fullscreen = !OS.window_fullscreen;

func _init():
	# Reset vars
	game_time = 10.0;
	timecycle_ratio = 1.0 / 60.0;
	
	# 1 day in game = 30 minutes real life
	timecycle_ratio *= 24.0 / 30.0;

func _process(delta):
	game_time += timecycle_ratio * delta;
	game_time = fmod(game_time, 24.0);
	real_time += 1.0 / 60.0 * delta;
