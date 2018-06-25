extends StaticBody

export var _item_name = "";
var item_id = -1;

func _ready():
	if (_item_name.length() > 0):
		# Find item by name
		var fid = item_database.get_item_by_name(_item_name);
		if (fid > 0):
			item_id = fid;
