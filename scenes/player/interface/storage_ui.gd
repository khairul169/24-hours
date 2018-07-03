extends Control

# Nodes
onready var interface = get_parent();
onready var player = interface.get_parent();
onready var item_container = $item_list/container/items;

# Scenes
onready var item_list_scene = load("res://scenes/player/interface/storage_item.tscn");

# Variables
var storage_object;

func _ready():
	interface.register_itemdrop_control($item_list, self, "_item_drop");

func toggled(object = null):
	if (storage_object):
		storage_object.disconnect("item_updated", self, "_storage_updated");
		storage_object = null;
	
	if (object):
		storage_object = object;
		storage_object.connect("item_updated", self, "_storage_updated");

func refresh_items():
	if (!visible || !storage_object):
		return;
	
	for i in item_container.get_children():
		i.queue_free();
	
	for id in range(storage_object.items.size()):
		var item = storage_object.items[id];
		#for j in range(item.amount):
		var instance = item_list_scene.instance();
		item_container.add_child(instance);
		
		instance.source = 2;
		instance.interface = interface;
		instance.set_data({
			'id': id,
			'title': item_database.get_item_title(item.item_id),
			'icon': item_database.get_item_icon(item.item_id),
			'amount': item.amount
		});
		instance.storage = storage_object;
		instance.connect("released", self, "_item_released");

func _storage_updated():
	refresh_items();

func _item_released(obj):
	var all = Input.is_key_pressed(KEY_CONTROL);
	interface.inventory.grab_from_storage(obj, all);

func _item_drop(object):
	if (object.source == 0):
		_add_from_inventory(object);

func _add_from_inventory(object):
	if (!player.inventory || object.source != 0 || !storage_object):
		return;
	
	var item_id = player.inventory.get_item_id(object.id);
	if (!item_id):
		return;
	var amount = player.inventory.get_item_amount(object.id);
	if (item_id && player.inventory.remove_item(object.id, amount)):
		storage_object.add_item(item_id, amount);
