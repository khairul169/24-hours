extends Control

# Nodes
onready var player = get_parent();
onready var inventory = $inventory;

func _ready():
	inventory.hide();

func capture_mouse(capture):
	if (capture):
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED);
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE);

func _input(event):
	if (event is InputEventKey):
		if (event.pressed && event.scancode == KEY_TAB):
			toggle_inventory();

func toggle_inventory():
	if (!inventory.visible):
		inventory.show();
		inventory.refresh_items();
		inventory.grab_focus();
		capture_mouse(false);
	
	else:
		inventory.hide();
		capture_mouse(true);
