extends Control

# Signals
signal pick_item(id);
signal item_used(id);
signal item_drop(id, all);
signal item_pressed(id);

# Variables
var id = -1;
var icon = null;
var title = "";
var pickable = false;
var usable = false;
var last_press = 0.0;

func _ready():
	$item_action/btn_use.connect("pressed", self, "_use");
	$item_action/btn_drop.connect("pressed", self, "_drop");
	
	toggle_action(false);

func update_item():
	if (icon):
		$item_data/icon.texture = icon;
	
	$item_data/title.text = title;
	$item_action/btn_use.disabled = !usable;

func toggle_action(show):
	if (show && !pickable):
		$item_action.show();
		grab_focus();
	else:
		$item_action.hide();
		release_focus();

func is_action_visible():
	return $item_action.visible;

func _process(delta):
	if (last_press < 1.0):
		last_press += delta;

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
