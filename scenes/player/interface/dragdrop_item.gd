extends Control

# Signals
signal pressed(obj);
signal released(obj);

# Variables
var interface;
var rect_object = self;
var source = -1;
var drag_icon = null;
var pressed = false;

func _input(event):
	if (event is InputEventMouseButton):
		if (!rect_object):
			return;
		
		var pos = event.global_position;
		var in_rect = rect_object.get_global_rect().has_point(pos);
		
		if (event.button_index == BUTTON_LEFT && in_rect):
			if (event.pressed && !pressed):
				if (interface && interface.has_method("item_pressed")):
					interface.item_pressed(self);
				emit_signal("pressed", self);
				pressed = true;
			
			if (pressed && !event.pressed && in_rect):
				emit_signal("released", self);
				pressed = false;
