extends Node

# Item identifier
enum {
	ITEM_NONE = 0,
	ITEM_STICK,
	
	# Medic item
	ITEM_THERMOMETER
};

class Item extends Reference:
	var id = 0;
	var weight = 0.0;
	var name = "";
	var icon = null;
	var max_stacks = 0;
	var usable = false;
	var scene = null;
	
	func _init(id, name, weight, usable, max_stacks = 1):
		# Set item data
		self.id = id;
		self.weight = weight;
		self.name = name;
		self.max_stacks = max_stacks;
		self.usable = usable;
		
		# Load item icon
		var icon_path = "res://assets/sprites/items/" + name + ".png";
		if (File.new().file_exists(icon_path)):
			self.icon = load(icon_path);
	
	func set_scene(path):
		if (!File.new().file_exists(path)):
			print("Cannot load scene! File is not exist. ", path);
			return;
		scene = load(path);

var items = {};
var usable_fuels = {
	ITEM_STICK: 30.0
};
var item_title = {};
var item_description = {};

func _ready():
	# Item list
	register_item(ITEM_STICK, "stick", 0.2, false, 10);
	register_item(ITEM_THERMOMETER, "thermometer", 0.8, true);
	
	# Item world scene
	set_item_scene(ITEM_STICK, "res://assets/props/stick/stick.tscn");
	set_item_scene(ITEM_THERMOMETER, "res://assets/weapon/thermometer/world_item.tscn");
	
	# Item title and description
	item_title[ITEM_STICK] = "Stick";
	item_description[ITEM_STICK] = "Just a lonely stick. Can be used as a fuel source.";
	item_title[ITEM_THERMOMETER] = "Thermometer";
	item_description[ITEM_THERMOMETER] = "Ancient stuff that can be used to examine body temperature.";

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

func get_item_icon(id):
	if (items.has(id)):
		return items[id].icon;
	return null;

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

func get_item_title(id):
	if (item_title.has(id)):
		return item_title[id];
	return get_item_name(id);

func get_item_description(id):
	if (item_description.has(id)):
		return item_description[id];
	return "";
