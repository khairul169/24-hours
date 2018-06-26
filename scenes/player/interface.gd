extends Control

# Nodes
onready var player = get_parent();
onready var inventory = $inventory;
onready var campfire = $campfire;

# Variables
var mouse_handler = [];

func _ready():
	inventory.hide();
	campfire.hide();
	mouse_handler.clear();

func handle_mouse(handler, handle):
	if (handle && !mouse_handler.has(handler)):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE);
		mouse_handler.append(handler);
	
	else:
		if (mouse_handler.has(handler)):
			mouse_handler.erase(handler);
		
		if (mouse_handler.empty()):
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED);

func _input(event):
	if (event is InputEventKey):
		if (event.pressed && event.scancode == KEY_TAB):
			toggle_inventory();

func toggle_inventory():
	if (!inventory.visible):
		inventory.show();
		inventory.refresh_items();
		inventory.grab_focus();
		handle_mouse("inventory", true);
	
	else:
		inventory.hide();
		handle_mouse("inventory", false);
		
		if (campfire.visible):
			toggle_campfire();

func toggle_campfire(object = null):
	if (!campfire.visible):
		if (!object):
			return;
		
		campfire.show();
		campfire.campfire_object = object;
		handle_mouse("campfire", true);
		
		if (!inventory.visible):
			toggle_inventory();
	else:
		campfire.hide();
		handle_mouse("campfire", false);
		
		if (inventory.visible):
			toggle_inventory();
