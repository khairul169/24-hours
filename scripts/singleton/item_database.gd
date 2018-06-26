extends Node

# Item identifier
enum {
	ITEM_NONE = 0,
	ITEM_STICK,
	ITEM_BRANCH,
	ITEM_STONE
};

class Item extends Reference:
	var id = 0;
	var weight = 0.0;
	var name = "";
	var max_stacks = 0;
	var usable = false;
	var scene = null;
	
	func _init(id, name, weight, usable, max_stacks = 1):
		self.id = id;
		self.weight = weight;
		self.name = name;
		self.max_stacks = max_stacks;
		self.usable = usable;
	
	func set_scene(path):
		if (!File.new().file_exists(path)):
			print("Cannot load scene! File is not exist. ", path);
			return;
		scene = load(path);

var items = {};

func _ready():
	# Item list
	register_item(ITEM_STICK, "stick", 0.2, false, 10);
	register_item(ITEM_BRANCH, "branch", 0.5, true);
	register_item(ITEM_STONE, "stone", 0.5, false, 10);
	
	# Item world scene
	set_item_scene(ITEM_STICK, "res://assets/props/stick/stick.tscn");

############################################################################

func register_item(id, name, weight, usable, max_stacks = 1):
	items[id] = Item.new(id, name, weight, usable, max_stacks);

func set_item_scene(id, path):
	if (items.has(id)):
		items[id].set_scene(path);

func is_item_valid(id):
	return items.has(id);

func get_item_by_name(name):
	var return_id = ITEM_NONE;
	for i in items.values():
		if (name.casecmp_to(i.name) != 0):
			continue;
		return_id = i.id;
		break;
	return return_id;

func get_item_name(id):
	if (items.has(id)):
		return items[id].name;
	return "";

func get_item_scene(id):
	if (items.has(id)):
		return items[id].scene;
	return null;

func get_item_weight(id):
	if (items.has(id)):
		return items[id].weight;
	return 0.0;

func is_item_usable(id):
	if (items.has(id)):
		return items[id].usable;
	return false;

func is_item_stackable(id):
	if (items.has(id)):
		return (items[id].max_stacks > 1);
	return false;

func get_item_maxstack(id):
	if (items.has(id)):
		return items[id].max_stacks;
	return false;
