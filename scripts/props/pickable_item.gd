extends StaticBody

export var item_name = "";
export (NodePath) var base_scene;

var item_id = 0;
var is_valid = false;

func _ready():
	if (item_name.length() > 0):
		# Find item by name
		var fid = item_database.get_item_by_name(item_name);
		if (fid > 0):
			item_id = fid;
	
	if (item_id > 0):
		add_to_group("pickable_items");
		is_valid = true;
	
	if (base_scene != null && typeof(base_scene) == TYPE_NODE_PATH):
		base_scene = get_node(base_scene);

func remove_from_world():
	is_valid = false;
	
	if (!get_parent().is_queued_for_deletion()):
		get_parent().queue_free();
