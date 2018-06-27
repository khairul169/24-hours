extends Control

# Signals
signal pick_item(id);
signal item_used(id);
signal item_drop(id, all);
signal item_pressed(id);

# Variables
var id = -1;
var pickable = false;

func _ready():
	$item_action/btn_use.connect("pressed", self, "_use");
	$item_action/btn_drop.connect("pressed", self, "_drop");
	toggle_action(false);

func update_item(data):
	id = data.id;
	pickable = data.pickable;
	
	# Icon
	var icon = item_database.get_item_icon(data.item_id);
	if (icon):
		$item_data/icon.texture = icon;
	
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
	
	if (data.usable):
		$item_action/btn_use.disabled = false;
	else:
		$item_action/btn_use.disabled = true;

func toggle_action(show):
	if (show && !pickable):
		$item_action.show();
		grab_focus();
	else:
		$item_action.hide();
		release_focus();

func is_action_visible():
	return $item_action.visible;

func _input(event):
	if (event is InputEventMouseButton):
		var in_rect = $item_data/hover_area.get_global_rect().has_point(event.global_position);
		
		if (event.button_index == BUTTON_LEFT):
			if (event.pressed && in_rect && !pickable):
				emit_signal("item_pressed", id);
			
			if (!event.pressed && in_rect):
				if (pickable):
					emit_signal("pick_item", id);
				else:
					toggle_action(!is_action_visible());

func _use():
	emit_signal("item_used", id);

func _drop():
	var all = Input.is_key_pressed(KEY_CONTROL);
	emit_signal("item_drop", id, all);
