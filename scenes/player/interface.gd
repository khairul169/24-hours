extends Control

const DRAG_PREVIEW_SIZE = 48.0;

# Nodes
onready var player = get_parent();
onready var background = $background;
onready var inventory = $inventory;
onready var campfire = $campfire;
onready var use_prog = $use_prog;
onready var storage_ui = $storage_ui;

# Variables
var mouse_handler = [];
var use_progress_time = 0.0;
var use_progress_curr = 0.0;

var drag_preview;
var itemdrop_controls = [];
var item_dragged = null;

func _ready():
	# Reset everything
	toggle_inventory(false);
	mouse_handler.clear();
	use_prog.hide();
	use_prog.value = 0.0;
	
	# Create drag preview node
	drag_preview = TextureRect.new();
	add_child(drag_preview);
	drag_preview.name = "drag_preview"
	drag_preview.expand = true;
	drag_preview.rect_size = Vector2(1.0, 1.0) * DRAG_PREVIEW_SIZE;
	drag_preview.hide();
	
	background.hide();
	get_tree().connect("screen_resized", self, "_resized");

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
			toggle_inventory(!inventory.visible);
		
		if (event.scancode == KEY_ESCAPE):
			hide_all();
	
	if (event is InputEventMouseButton):
		if (item_dragged != null && !event.pressed && event.button_index == BUTTON_LEFT):
			item_dropped(event.global_position);
			item_dragged = null;
			drag_preview.hide();
	
	if (event is InputEventMouseMotion):
		if (item_dragged != null):
			if (!drag_preview.visible && player.inventory):
				if (item_dragged.drag_icon):
					drag_preview.texture = item_dragged.drag_icon;
				drag_preview.show();
			drag_preview.rect_global_position = event.global_position - (Vector2(1.0, 1.0) * DRAG_PREVIEW_SIZE / 2);

func _process(delta):
	if (inventory.visible || campfire.visible || storage_ui.visible):
		background.show();
	else:
		background.hide();
	
	if (use_prog.visible):
		if (use_progress_curr >= use_progress_time):
			use_prog.hide();
		else:
			use_progress_curr = min(use_progress_curr + delta, use_progress_time);
			use_prog.value = (use_progress_curr / use_progress_time) * 100.0;

func _resized():
	background.rect_global_position = Vector2();
	background.rect_size = get_viewport().size;

func toggle_inventory(show = false):
	if (show):
		inventory.show();
		inventory.refresh_items();
		handle_mouse("inventory", true);
		
		if (campfire.visible || storage_ui.visible):
			inventory.rect_position = Vector2(20, 20);
			inventory.set_anchors_preset(Control.PRESET_LEFT_WIDE);
		else:
			inventory.rect_position = (get_rect().size - inventory.get_rect().size) / 2.0;
			inventory.set_anchors_preset(Control.PRESET_VCENTER_WIDE);
	
	else:
		inventory.hide();
		handle_mouse("inventory", false);
		
		if (campfire.visible):
			toggle_campfire();
		if (storage_ui.visible):
			toggle_storage();

func toggle_campfire(object = null):
	if (object):
		campfire.show();
		campfire.campfire_object = object;
		handle_mouse("campfire", true);
		toggle_inventory(true);
	else:
		campfire.hide();
		handle_mouse("campfire", false);
		toggle_inventory();

func toggle_storage(object = null):
	if (object):
		storage_ui.show();
		storage_ui.toggled(object);
		storage_ui.refresh_items();
		handle_mouse("storage", true);
		toggle_inventory(true);
	else:
		storage_ui.hide();
		storage_ui.toggled();
		handle_mouse("storage", false);
		toggle_inventory();

func hide_all():
	toggle_inventory();
	toggle_campfire();
	toggle_storage();

func show_use_progress(time):
	use_progress_time = time;
	use_progress_curr = 0.0;
	use_prog.show();

func hide_use_progress():
	use_prog.value = 0.0;
	use_prog.hide();

func register_itemdrop_control(node, target, method):
	itemdrop_controls.append({
		'node': node,
		'target': target,
		'method': method
	});

func item_pressed(object):
	if (!object is preload("res://scenes/player/interface/dragdrop_item.gd")):
		return;
	item_dragged = object;

func item_dropped(pos):
	if (!item_dragged):
		return;
	
	for i in itemdrop_controls:
		if (!i.node.visible || !i.node.get_global_rect().has_point(pos)):
			continue;
		if (i.target && i.target.has_method(i.method)):
			i.target.call(i.method, item_dragged);
