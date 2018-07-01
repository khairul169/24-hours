extends Control

# Nodes
onready var interface = get_parent();
onready var inventory = get_node("../../inventory");

# UI node
onready var label_estimation = $overview/label_estimation;
onready var item_icon = $overview/fuel_box/item_icon;
onready var item_amount = $overview/fuel_box/item_amount;

# Variables
var campfire_object = null;
var next_check = 0.0;

func _ready():
	campfire_object = null;
	interface.register_itemdrop_control($overview/fuel_box, self, "_item_dropped");
	item_icon.hide();

func _item_dropped(object):
	if (object.source != 0 || !campfire_object || !inventory):
		return;
	
	# Not a burnable materials
	var item_id = inventory.get_item_id(object.id);
	if (!campfire_object.fuel_compatible(item_id)):
		return;
	
	var amount = 1;
	if (Input.is_key_pressed(KEY_CONTROL)):
		amount = inventory.get_item_amount(object.id);
	if (inventory.remove_item(object.id, amount)):
		campfire_object.add_fuel(item_id, amount);

func _process(delta):
	if (!visible || !campfire_object):
		return;
	
	if (next_check > 0.0):
		next_check -= delta;
	else:
		next_check = 0.1;
		
		label_estimation.text = str(campfire_object.get_estimation()).pad_decimals(2);
		
		if (campfire_object.fuels.amount > 0 && campfire_object.fuels.item_id > 0):
			item_icon.show();
			item_icon.texture = item_database.get_item_icon(campfire_object.fuels.item_id);
			
			item_amount.show();
			item_amount.text = str(campfire_object.fuels.amount);
		else:
			item_icon.hide();
			item_amount.hide();
