extends Node

const CAST_RANGE = 10.0;
const USE_KEY = KEY_E;

const PROP_CAMPFIRE = preload("res://scenes/props/campfire.gd");

# Nodes
onready var interface = get_node("../interface");
onready var camera = get_node("../camera");
onready var space_state = get_parent().get_world().direct_space_state;

# vars
var _next_use = false;

func _ready():
	_next_use = false;

func _input(event):
	if (event is InputEventKey && event.pressed && event.scancode == USE_KEY && !_next_use):
		_next_use = true;

func _physics_process(delta):
	if (_next_use && space_state):
		_next_use = false;
		
		var ray_result = space_state.intersect_ray(camera.global_transform.origin, camera.global_transform.xform(Vector3(0, 0, -CAST_RANGE)), [get_parent()]);
		if (ray_result != null && !ray_result.empty()):
			check_object(ray_result.collider);

func check_object(object):
	if (object is PROP_CAMPFIRE):
		interface.toggle_campfire(object);
