extends "dragdrop_item.gd"

var id = -1;
var storage;

func _ready():
	rect_object = $rect_obj;

func set_data(data):
	id = data.id;
	
	if (data.icon):
		$icon.texture = data.icon;
		drag_icon = data.icon;
	
	if (data.title):
		self.hint_tooltip = data.title;
	
	if (data.amount && data.amount > 1):
		$amount.text = str(data.amount);
	else:
		$amount.queue_free();
