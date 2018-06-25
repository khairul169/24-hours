extends Control

# Signals
signal item_used(id);
signal item_drop(id);

# Variables
var id = -1;

func _ready():
	$item_action/btn_use.connect("pressed", self, "_use");
	$item_action/btn_drop.connect("pressed", self, "_drop");
	
	toggle_action(false);

func set_title(title):
	$item_data/title.text = title;

func set_icon(icon):
	$item_data/icon.texture = icon;

func set_usable(usable):
	$item_action/btn_use.disabled = !usable;

func toggle_action(show):
	if (show):
		$item_action.show();
		grab_focus();
	else:
		$item_action.hide();
		release_focus();

func is_action_visible():
	return $item_action.visible;

func _input(event):
	if (event is InputEventMouseButton):
		if (event.button_index == BUTTON_LEFT):
			if (!event.pressed && $item_data/hover_area.get_global_rect().has_point(event.global_position)):
				toggle_action(!is_action_visible());

func _use():
	emit_signal("item_used", id);

func _drop():
	emit_signal("item_drop", id);
