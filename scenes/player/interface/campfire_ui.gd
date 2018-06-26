extends Control

# Nodes
onready var inventory = get_node("../../inventory");
onready var inventory_ui = get_node("../inventory");

# UI node
onready var label_estimation = $overview/label_estimation;

# Variables
var campfire_object = null;
var next_check = 0.0;

func _ready():
	campfire_object = null;
	inventory_ui.register_itemdrop_control($overview/fuel_box, self, "on_item_dropped");

func on_item_dropped(id):
	if (!campfire_object || !inventory):
		return;
	
	# Not a burnable materials
	var item_id = inventory.get_item_id(id);
	if (!item_id in item_database.usable_fuels):
		return;
	
	if (inventory.remove_item(id, 1)):
		campfire_object.add_fuel(item_id);

func _process(delta):
	if (!visible || !campfire_object):
		return;
	
	if (next_check > 0.0):
		next_check -= delta;
	else:
		next_check = 0.1;
		
		if (campfire_object.has_method("get_estimation")):
			var est = campfire_object.get_estimation();
			label_estimation.text = str(est).pad_decimals(2);
