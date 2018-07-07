extends Node

const CAST_RANGE = 2.5;
const USE_KEY = KEY_E;

const PROP_CAMPFIRE = preload("res://scenes/props/campfire.gd");
const PROP_STORAGE = preload("res://scripts/props/storage.gd");

# Resource
export (Material) var placeholder_material;

# Nodes
onready var player = get_parent();
onready var interface = player.get_node("interface");
onready var camera = player.get_node("camera");
onready var space_state = player.get_world().direct_space_state;
onready var inventory = player.get_node("inventory");

# Variables
var pressing = false;
var time_left = 0.0;
var next_think = 0.0;
var screen_ray = null;

# Structure placing
var is_placing = false;
var item_slot = -1;
var placeholder_obj;
var obj_rotation = 0.0;

func _ready():
	# Reset variable
	pressing = false;
	time_left = 0.0;
	screen_ray = null;
	is_placing = false;
	item_slot = -1;
	
	# Structure placeholder
	placeholder_obj = MeshInstance.new();
	placeholder_obj.name = "structure_placeholder";
	placeholder_obj.material_override = placeholder_material;
	placeholder_obj.cast_shadow = MeshInstance.SHADOW_CASTING_SETTING_OFF;

func _physics_process(delta):
	if (!space_state):
		return;
	
	var ray_test = space_state.intersect_ray(camera.global_transform.origin, camera.global_transform.xform(Vector3(0, 0, -CAST_RANGE)), [get_parent()]);
	if (ray_test.size() > 0):
		screen_ray = {
			'origin': ray_test.position,
			'object': ray_test.collider,
			'normal': ray_test.normal
		};
	else:
		screen_ray = null;

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
	
	if (Input.is_key_pressed(KEY_R) && is_placing):
		obj_rotation = fmod(obj_rotation + deg2rad(180) * delta, 2*PI);
	
	if (is_placing && placeholder_obj.is_inside_tree()):
		# Reset object transform
		placeholder_obj.transform = Transform();
		
		var test = Basis();
		test = test.rotated(Vector3(1, 0, 0), -PI/2.0);
		
		var placeholder_col = Color(1, 0, 0, 0.4);
		
		if (screen_ray):
			placeholder_col = Color(1, 1, 1, 0.4);
			placeholder_obj.transform = utils.align_to_normal(placeholder_obj.transform, screen_ray.normal);
			placeholder_obj.transform = placeholder_obj.transform.rotated(screen_ray.normal, obj_rotation);
			placeholder_obj.global_transform.origin = screen_ray.origin;
		
		else:
			placeholder_obj.transform = placeholder_obj.transform.rotated(Vector3(0, 1, 0), obj_rotation);
			placeholder_obj.global_transform.origin = camera.global_transform.xform(Vector3(0, 0, -CAST_RANGE));
		
		# Set material color
		if (placeholder_material):
			placeholder_material.albedo_color = placeholder_col;

func current_usable():
	if (is_placing && screen_ray):
		return true;
	if (!screen_ray):
		return false;
	
	return (screen_ray.object is PROP_CAMPFIRE ||
			screen_ray.object is PROP_STORAGE);

func get_use_time():
	if (is_placing || !screen_ray):
		return 0.5;
	
	if (screen_ray.object is PROP_CAMPFIRE):
		return 0.4;
	
	if (screen_ray.object is PROP_STORAGE):
		if (screen_ray.object.is_opened):
			return 0.5;
		else:
			return 1.0;
	
	return 1.0;

func use_current_object():
	if (!current_usable()):
		return;
	
	if (is_placing && item_slot >= 0):
		place_structure();
		return;
	
	if (screen_ray.object is PROP_CAMPFIRE):
		interface.toggle_campfire(screen_ray.object);
	
	if (screen_ray.object is PROP_STORAGE):
		screen_ray.object.is_opened = true;
		interface.toggle_storage(screen_ray.object);

func use_structure(slot_id):
	if (slot_id >= 0 && slot_id < inventory.items.size()):
		is_placing = true;
		item_slot = slot_id;
		
		var placeholder_mesh = item_database.get_structure_data(inventory.get_item_id(slot_id)).placeholder;
		if (placeholder_mesh):
			placeholder_obj.mesh = placeholder_mesh;
			player.scene.add_child(placeholder_obj);
		
		elif (placeholder_obj.is_inside_tree()):
			placeholder_obj.get_parent().remove_child(placeholder_obj);
	else:
		if (placeholder_obj.is_inside_tree()):
			placeholder_obj.get_parent().remove_child(placeholder_obj);
		
		is_placing = false;
		item_slot = -1;

func place_structure():
	if (!is_placing || item_slot < 0 || item_slot >= inventory.items.size() || !screen_ray):
		return;
	
	var item_id = inventory.get_item_id(item_slot);
	if (!item_database.is_structure(item_id)):
		return;
	
	# Create object instance
	var obj_scene = item_database.get_structure_data(item_id).scene;
	var instance = obj_scene.instance();
	instance.name = "st_" + item_database.get_item_name(item_id);
	player.scene.add_child(instance, true);
	
	# Set object transform
	instance.transform = utils.align_to_normal(Transform(), screen_ray.normal);
	instance.transform = placeholder_obj.transform.rotated(screen_ray.normal, obj_rotation);
	instance.global_transform.origin = screen_ray.origin;
	
	# Remove item from inventory
	inventory.remove_item(item_slot, 1);
	inventory.unequip_item();
