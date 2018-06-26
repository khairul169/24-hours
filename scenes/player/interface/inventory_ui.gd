extends Control

export (PackedScene) var item_list_scene;

# Nodes
onready var inventory = get_node("../../inventory");
onready var item_picker = get_node("../../item_picker");

# UI node
onready var near_item_container = $near/base/scroll_container/container;
onready var bag_item_container = $bag/base/scroll_container/container;
onready var bag_capacity_label = $bag/capacity;

# Variables
var near_items = [];
var bag_items = [];
var next_update = 0.0;

func _ready():
	pass

func reset():
	# Reset item
	near_items.clear();
	bag_items.clear();
	refresh_items();

func update_interface(container, item_list):
	for i in container.get_children():
		i.queue_free();
	
	if (!item_list_scene):
		return;
	
	for i in range(item_list.size()):
		# Instance item
		var instance = item_list_scene.instance();
		container.add_child(instance);
		
		# Update item data
		instance.id = item_list[i].id;
		instance.title = item_list[i].title;
		instance.pickable = item_list[i].pickable;
		instance.usable = item_list[i].usable;
		instance.update_item();
		
		instance.connect("pick_item", self, "on_item_pick");
		instance.connect("item_used", self, "on_item_used");
		instance.connect("item_drop", self, "on_item_drop");

func refresh_items():
	if (!item_picker || !inventory):
		return;
	
	# Nearest item
	var _near = item_picker.check_near_item();
	near_items.clear();
	
	for id in item_picker.nearest_item:
		var amount = item_picker.nearest_item[id].size();
		var item_name = item_database.get_item_name(id);
		
		if (item_database.is_item_stackable(id) && amount > 1):
			item_name += str(" (", amount, "x)");
			amount = 1;
		
		for i in range(amount):
			near_items.append({
			'id': id,
			'title': item_name,
			'pickable': true,
			'usable': false
		});
	update_interface(near_item_container, near_items);
	
	# Bag item
	bag_items.clear();
	for i in range(inventory.items.size()):
		var item = inventory.items[i];
		var item_name = item_database.get_item_name(item.id);
		if (item.amount > 1):
			item_name += str(" (", int(item.amount), "x)");
		
		bag_items.append({
			'id': i,
			'title': item_name,
			'pickable': false,
			'usable': item_database.is_item_usable(item.id)
		});
	update_interface(bag_item_container, bag_items);
	
	# Bag capacity
	bag_capacity_label.text = str(inventory.cur_capacity).pad_decimals(1) + "/" + str(inventory.capacity).pad_decimals(1) + " kg";
	
	# Label color
	""" IDK how to change label font color >:O
	if (inventory.is_over_capacity()):
		bag_capacity_label.font_color = Color("#333");
	else:
		bag_capacity_label.font_color = Color("#333");
	"""

func on_item_pick(id):
	if (item_picker && item_picker.has_method("pick_near_item")):
		if (Input.is_key_pressed(KEY_CONTROL) && item_picker.has_method("get_near_item_amount")):
			item_picker.pick_near_item(id, item_picker.get_near_item_amount(id));
		else:
			item_picker.pick_near_item(id, 1);
		refresh_items();

func on_item_used(id):
	if (inventory && inventory.has_method("use_item")):
		inventory.use_item(id);

func on_item_drop(id, all):
	if (inventory && inventory.has_method("drop_item")):
		if (all && inventory.has_method("get_item_amount")):
			inventory.drop_item(id, inventory.get_item_amount(id));
		else:
			inventory.drop_item(id, 1);
