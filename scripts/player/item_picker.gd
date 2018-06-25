extends Node

const PICK_RANGE = 10.0;
const PICKABLE_ITEM_SCRIPT = preload("res://scenes/props/pickable_item.gd");
const PICK_ITEM_KEY = KEY_F;

# Nodes
onready var player = get_parent();
onready var camera = get_node("../camera");
onready var space_state = player.get_world().direct_space_state;
onready var inventory = get_node("../inventory");

# Variables
var highlighted_object = null;

func _ready():
	pass

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
	if (!highlighted_object || !inventory):
		return;
	
	# Add item to player inventory
	inventory.add_item(highlighted_object.id);
	
	# Remove item from world
	highlighted_object.node.queue_free();
	highlighted_object = null;
