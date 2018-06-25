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
	
	func _init(id, name, weight, usable, max_stacks = 1):
		self.id = id;
		self.weight = weight;
		self.name = name;
		self.max_stacks = max_stacks;
		self.usable = usable;

var items = {};

func _ready():
	register_item(ITEM_STICK, "stick", 0.1, false, 30);
	register_item(ITEM_BRANCH, "branch", 0.3, false);
	register_item(ITEM_STONE, "stone", 0.5, false, 10);

func register_item(id, name, weight, usable, max_stacks = 1):
	items[id] = Item.new(id, name, weight, usable, max_stacks);

func get_item_name(id):
	if (items.has(id)):
		return items[id].name;
	return "";

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
