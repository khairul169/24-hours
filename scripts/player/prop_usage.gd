extends Node

const CAST_RANGE = 2.0;
const USE_KEY = KEY_E;

const PROP_CAMPFIRE = preload("res://scenes/props/campfire.gd");

# Nodes
onready var interface = get_node("../interface");
onready var camera = get_node("../camera");
onready var space_state = get_parent().get_world().direct_space_state;

# vars
var pressing = false;
var time_left = 0.0;
var next_think = 0.0;
var current_object = null;

func _ready():
	pressing = false;
	time_left = 0.0;
	current_object = null;

func _physics_process(delta):
	if (!space_state):
		return;
	
	var ray_result = space_state.intersect_ray(camera.global_transform.origin, camera.global_transform.xform(Vector3(0, 0, -CAST_RANGE)), [get_parent()]);
	if (ray_result != null && !ray_result.empty()):
		current_object = ray_result.collider;
	else:
		current_object = null;

func _process(delta):
	if (Input.is_key_pressed(USE_KEY) && !interface.is_busy() && current_usable()):
		if (!pressing):
			pressing = true;
			time_left = get_use_time();
			interface.show_use_progress(time_left);
		else:
			time_left -= delta;
		
		if (time_left <= 0.0):
			pressing = false;
			use_current_object();
			interface.hide_use_progress();
	else:
		if (pressing):
			pressing = false;
			interface.hide_use_progress();

func current_usable():
	if (!current_object):
		return false;
	if (current_object is PROP_CAMPFIRE):
		return true;
	return false;

func get_use_time():
	if (!current_object):
		return 1.0;
	if (current_object is PROP_CAMPFIRE):
		return 0.4;
	return 1.0;

func use_current_object():
	if (current_object is PROP_CAMPFIRE):
		interface.toggle_campfire(current_object);
