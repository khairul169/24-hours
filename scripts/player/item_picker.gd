extends Node

const PICK_RANGE = 10.0;
const NEAR_ITEM_RANGE = 5.0;
const PICKABLE_ITEM_SCRIPT = preload("res://scripts/props/pickable_item.gd");
const PICK_ITEM_KEY = KEY_F;

# Nodes
onready var player = get_parent();
onready var camera = get_node("../camera");
onready var space_state = player.get_world().direct_space_state;
onready var inventory = get_node("../inventory");

# Variables
var highlighted_object = null;
var nearest_item = {};
var next_check = 0.0;

func _physics_process(delta):
	if (!camera.current || !space_state):
		return;
	
	var ray_test = space_state.intersect_ray(camera.global_transform.origin, camera.global_transform.xform(Vector3(0, 0, -PICK_RANGE)), [player]);
	if (ray_test != null && !ray_test.empty() && ray_test.collider is PICKABLE_ITEM_SCRIPT):
		var item_id = ray_test.collider.item_id;
		if (item_database.is_item_valid(item_id)):
			highlighted_object = {
				"id": item_id,
				"node": ray_test.collider
			};
		
		else:
			highlighted_object = null;
	else:
		highlighted_object = null;

func _input(event):
	if (event is InputEventKey && event.pressed && event.scancode == PICK_ITEM_KEY):
		_pick_highlighted();

func _pick_highlighted():
	if (highlighted_object):
		pick_item(highlighted_object.node);
		highlighted_object = null;

func pick_item(object):
	if (!inventory || !object is PICKABLE_ITEM_SCRIPT):
		return;
	
	# Add item to player inventory
	inventory.add_item(object.item_id);
	
	# Remove item from world
	object.remove_from_world();

func check_near_item():
	if (!player):
		return;
	var player_pos = player.global_transform.origin;
	nearest_item.clear();
	
	for object in get_tree().get_nodes_in_group("pickable_items"):
		if (player_pos.distance_to(object.global_transform.origin) > NEAR_ITEM_RANGE):
			continue;
		if (!object is PICKABLE_ITEM_SCRIPT || !object.is_valid):
			continue;
		if (nearest_item.has(object.item_id)):
			nearest_item[object.item_id].append(object);
		else:
			nearest_item[object.item_id] = [object];
	return nearest_item;

func pick_near_item(id, amount = 1):
	if (!nearest_item.has(id)):
		return;
	
	if (amount > 1 && !item_database.is_item_stackable(id)):
		amount = 1;
	
	# Loop through pick amount
	for i in range(min(amount, nearest_item[id].size())):
		var item = nearest_item[id][0];
		
		var distance = player.global_transform.origin.distance_to(item.global_transform.origin);
		if (distance > NEAR_ITEM_RANGE):
			continue;
		
		pick_item(item);
		nearest_item[id].remove(0);
	
	# Refresh near item list
	check_near_item();

func get_near_item_amount(id):
	if (nearest_item.has(id) && !nearest_item[id].empty()):
		return nearest_item[id].size();
	return 0;
