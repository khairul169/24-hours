extends "dragdrop_item.gd"

# Signals
signal item_used(object);
signal item_drop(object, all);

# Variables
var id = -1;
var usable = false;

func _ready():
	rect_object = $item_data/hover_area;
	connect("released", self, "_released");
	toggle_action(false);
	
	$item_action/btn_use.connect("pressed", self, "_use");
	$item_action/btn_drop.connect("pressed", self, "_drop");

func update_item(data):
	id = data.id;
	
	# Icon
	var icon = item_database.get_item_icon(data.item_id);
	if (icon):
		$item_data/icon.texture = icon;
		drag_icon = icon;
	
	# Title
	var title = item_database.get_item_title(data.item_id);
	if (title.length() > 0):
		$item_data/title.text = title;
	else:
		$item_data/title.text = "#UNNAMED";
	
	# Tooltip
	$item_data/hover_area.hint_tooltip = item_database.get_item_description(data.item_id);
	
	# Amount
	if (data.size > 0):
		$item_data/amount.text = str(int(data.size), " pcs");
	else:
		$item_data/amount.text = "NULL";
	
	# Use button
	usable = data.usable;
	$item_action/btn_use.disabled = !usable;

func toggle_action(show):
	if (Input.is_key_pressed(KEY_SHIFT) && usable):
		_use();
		return;
	
	if (Input.is_key_pressed(KEY_CONTROL)):
		_drop();
	
	if (show && source == 0):
		$item_action.show();
		grab_focus();
	else:
		$item_action.hide();
		release_focus();

func is_action_visible():
	return $item_action.visible;

func _released(obj):
	if (source == 0):
		toggle_action(!is_action_visible());
		pressed = false;

func _use():
	if (usable && source == 0):
		emit_signal("item_used", self);

func _drop():
	if (source != 0):
		return;
	var all = Input.is_key_pressed(KEY_CONTROL);
	emit_signal("item_drop", self, all);
