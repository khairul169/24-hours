extends Control

# Nodes
onready var interface = get_parent();
onready var player = interface.get_parent();
onready var inventory = player.get_node("inventory");
onready var item_picker = player.get_node("item_picker");

# UI node
onready var near_item_container = $near/base/scroll_container/container;
onready var bag_item_container = $bag/base/scroll_container/container;
onready var bag_capacity_label = $bag/capacity;
onready var label_health = $state/label_health;
onready var label_hunger = $state/label_hunger;
onready var label_thirst = $state/label_thirst;

# Scenes
onready var item_list_scene = load("res://scenes/player/interface/inventory_item.tscn");

# Variables
var near_items = [];
var bag_items = [];
var next_update = 0.0;

func _ready():
	reset();
	interface.register_itemdrop_control($bag/base, self, "_item_dropped_at_bag");
	interface.register_itemdrop_control($near/base, self, "_item_dropped_at_near");

func reset():
	# Reset item
	near_items.clear();
	bag_items.clear();
	refresh_items();

func _process(delta):
	if (!visible):
		return;
	
	if (player):
		label_health.text = str(int(player.health)).pad_zeros(1) + "%";
		label_hunger.text = str(int(ceil(player.hunger * 100.0))).pad_zeros(1) + "%";
		label_thirst.text = str(int(ceil(player.thirst * 100.0))).pad_zeros(1) + "%";

func update_interface(container, item_list, inventory_item):
	for i in container.get_children():
		i.queue_free();
	
	if (!item_list_scene):
		return;
	
	for i in range(item_list.size()):
		# Instance item
		var instance = item_list_scene.instance();
		container.add_child(instance);
		
		# Update item data
		instance.interface = interface;
		if (inventory_item):
			instance.source = 0;
		else:
			instance.source = 1;
		instance.update_item(item_list[i]);
		
		if (inventory_item):
			instance.connect("item_used", self, "on_item_used");
			instance.connect("item_drop", self, "on_item_drop");
		else:
			instance.connect("released", self, "pick_near_item");
	
	# Clear items
	item_list.clear();

func refresh_items():
	if (!item_picker || !inventory):
		return;
	
	# Nearest item
	var _near = item_picker.check_near_item();
	near_items.clear();
	
	for id in item_picker.nearest_item:
		var amount = item_picker.nearest_item[id].size();
		var item_size = 1;
		
		if (item_database.is_item_stackable(id) && amount > 1):
			item_size = amount;
			amount = 1;
		
		for i in range(amount):
			near_items.append({
			'id': id,
			'item_id': id,
			'size': item_size,
			'usable': false
		});
	update_interface(near_item_container, near_items, false);
	
	# Bag item
	bag_items.clear();
	for i in range(inventory.items.size()):
		var item = inventory.items[i];
		var item_name = item_database.get_item_title(item.id);
		
		bag_items.append({
			'id': i,
			'item_id': item.id,
			'size': item.amount,
			'usable': item_database.is_item_usable(item.id)
		});
	update_interface(bag_item_container, bag_items, true);
	
	# Bag capacity
	bag_capacity_label.text = str(inventory.cur_capacity).pad_decimals(1) + "/" + str(inventory.capacity).pad_decimals(1) + " kg";
	
	# Label color
	if (inventory.is_over_capacity()):
		bag_capacity_label.add_color_override("font_color", Color("#ff3a3a"));
	else:
		bag_capacity_label.add_color_override("font_color", Color(1,1,1));

func on_item_used(object):
	if (object.source != 0):
		return;
	if (inventory && inventory.has_method("use_item")):
		inventory.use_item(object.id);

func on_item_drop(object, all):
	if (object.source != 0):
		return;
	if (inventory && inventory.has_method("drop_item")):
		if (all && inventory.has_method("get_item_amount")):
			inventory.drop_item(object.id, inventory.get_item_amount(object.id));
		else:
			inventory.drop_item(object.id, 1);

func pick_near_item(object, pick_all = false):
	if (object.source != 1):
		return;
	if (item_picker && item_picker.has_method("pick_near_item")):
		if ((pick_all || Input.is_key_pressed(KEY_CONTROL)) && item_picker.has_method("get_near_item_amount")):
			item_picker.pick_near_item(object.id, item_picker.get_near_item_amount(object.id));
		else:
			item_picker.pick_near_item(object.id, 1);
		refresh_items();

func _item_dropped_at_bag(object):
	if (object.source == 1):
		pick_near_item(object, true);

func _item_dropped_at_near(object):
	if (object.source == 0):
		on_item_drop(object, true);
