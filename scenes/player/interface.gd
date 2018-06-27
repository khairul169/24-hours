extends Control

# Nodes
onready var player = get_parent();
onready var inventory = $inventory;
onready var campfire = $campfire;
onready var use_prog = $use_prog;

# Variables
var mouse_handler = [];
var use_progress_time = 0.0;
var use_progress_curr = 0.0;

func _ready():
	# Reset everything
	inventory.hide();
	campfire.hide();
	mouse_handler.clear();
	use_prog.hide();
	use_prog.value = 0.0;

func handle_mouse(handler, handle):
	if (handle && !mouse_handler.has(handler)):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE);
		mouse_handler.append(handler);
	
	else:
		if (mouse_handler.has(handler)):
			mouse_handler.erase(handler);
		
		if (mouse_handler.empty()):
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED);

func is_busy():
	return Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED;

func _input(event):
	if (event is InputEventKey && event.pressed):
		if (event.scancode == KEY_TAB):
			toggle_inventory();
		
		if (event.scancode == KEY_ESCAPE):
			if (inventory.visible):
				toggle_inventory();
			if (campfire.visible):
				toggle_campfire();

func _process(delta):
	if (use_prog.visible):
		if (use_progress_curr >= use_progress_time):
			use_prog.hide();
		else:
			use_progress_curr = min(use_progress_curr + delta, use_progress_time);
			use_prog.value = (use_progress_curr / use_progress_time) * 100.0;

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

func show_use_progress(time):
	use_progress_time = time;
	use_progress_curr = 0.0;
	use_prog.show();

func hide_use_progress():
	use_prog.value = 0.0;
	use_prog.hide();
