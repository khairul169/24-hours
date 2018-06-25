extends Control

export (PackedScene) var item_list_scene;

# Nodes
onready var near_item_container = $near/base/scroll_container/container;
onready var bag_item_container = $bag/base/scroll_container/container;

# Player inventory
var inventory_mgr = null;

# Variables
var near_items = [];
var bag_items = [];

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
		#instance.set_icon(item_list[i].icon);
		instance.set_title(item_list[i].title);
		instance.set_usable(item_list[i].usable);
		
		instance.connect("item_used", self, "on_item_used");
		instance.connect("item_drop", self, "on_item_drop");

func refresh_items():
	if (!inventory_mgr):
		return;
	
	bag_items.clear();
	for i in range(inventory_mgr.items.size()):
		var item = inventory_mgr.items[i];
		var item_name = item_database.get_item_name(item.id);
		if (item.amount > 1):
			item_name += str(" (", int(item.amount), "x)");
		
		bag_items.append({
			'id': i,
			'title': item_name,
			'usable': item_database.is_item_usable(item.id)
		});
	
	update_interface(near_item_container, near_items);
	update_interface(bag_item_container, bag_items);

func on_item_used(id):
	if (inventory_mgr && inventory_mgr.has_method("use_item")):
		inventory_mgr.use_item(id);

func on_item_drop(id):
	if (inventory_mgr && inventory_mgr.has_method("drop_item")):
		inventory_mgr.drop_item(id);
