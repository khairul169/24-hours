extends Control

export (PackedScene) var item_list_scene;

# Nodes
onready var inventory = get_node("../../inventory");
onready var item_picker = get_node("../../item_picker");

# UI node
onready var near_item_container = $near/base/scroll_container/container;
onready var bag_item_container = $bag/base/scroll_container/container;

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
	if (item_picker):
		var _near = item_picker.nearest_item;
		near_items.clear();
		
		for i in range(item_picker.nearest_item.size()):
			var item = item_picker.nearest_item[i];
			var item_name = item_database.get_item_name(item.item_id);
			
			near_items.append({
				'id': i,
				'title': item_name,
				'pickable': true,
				'usable': false
			});
		
		update_interface(near_item_container, near_items);
	
	if (inventory):
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

func on_item_pick(id):
	if (item_picker):
		item_picker.pick_near_item(id);
		refresh_items();

func on_item_used(id):
	if (inventory && inventory.has_method("use_item")):
		inventory.use_item(id);

func on_item_drop(id, all):
	if (inventory && inventory.has_method("drop_item")):
		var amount = 1;
		if (all):
			amount = inventory.get_item_amount(id);
		inventory.drop_item(id, amount);
