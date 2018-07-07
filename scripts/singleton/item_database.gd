extends Node

# Item identifier
enum {
	ITEM_NONE = 0,
	ITEM_STICK,
	
	# Medic item
	ITEM_THERMOMETER
	
	# Edible foods
	ITEM_BOTTLED_WATER,
	ITEM_CANNED_TUNA
	
	# Structures
	ITEM_CAMPFIRE
};

var items = {};
var item_title = {};
var item_description = {};

# Item categories
var structures = {};

var usable_fuels = {
	ITEM_STICK: 30.0
};

var foods = {
	ITEM_CANNED_TUNA: 0.25
};

var drinks = {
	ITEM_BOTTLED_WATER: 0.4
};

func _init():
	# Item list
	register_item(ITEM_STICK, "stick", 0.2, false, 10);
	register_item(ITEM_THERMOMETER, "thermometer", 0.8, true);
	register_item(ITEM_BOTTLED_WATER, "bottled_water", 0.2, true);
	register_item(ITEM_CANNED_TUNA, "canned_tuna", 0.4, true);
	register_item(ITEM_CAMPFIRE, "campfire", 0.4, true);
	
	# Item world scene
	set_item_scene(ITEM_STICK, "res://assets/props/stick/stick.tscn");
	set_item_scene(ITEM_THERMOMETER, "res://assets/weapon/thermometer/world_item.tscn");
	set_item_scene(ITEM_BOTTLED_WATER, "res://assets/props/foods/bottled_water.tscn");
	set_item_scene(ITEM_CANNED_TUNA, "res://assets/props/foods/canned_tuna.tscn");
	
	# Item title and description
	translate_item(ITEM_STICK, "Stick", "Just a lonely stick. Can be used as a fuel source.");
	translate_item(ITEM_THERMOMETER, "Thermometer", "Ancient stuff that can be used to examine body temperature.");
	translate_item(ITEM_BOTTLED_WATER, "Bottled Water", "Fresh water from the nature");
	translate_item(ITEM_CANNED_TUNA, "Canned Tuna", "Free food laying around that are ready to eat.");
	
	# Structure data
	register_structure(ITEM_CAMPFIRE, "res://scenes/props/campfire.tscn", "res://assets/props/campfire/placeholder.mesh");

############################################################################

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

func register_item(id, name, weight, usable = false, max_stacks = 1):
	items[id] = Item.new(id, name, weight, usable, max_stacks);

func set_item_scene(id, path):
	if (items.has(id)):
		items[id].set_scene(path);

func translate_item(id, title, desc):
	item_title[id] = title;
	item_description[id] = desc;

func register_structure(id, scene, placeholder_mesh):
	structures[id] = {'scene': load(scene), 'placeholder': load(placeholder_mesh)};

func is_item_valid(id):
	return items.has(id);

func is_structure(id):
	return structures.has(id);

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

func get_structure_data(id):
	if (!structures.has(id)):
		return null;
	return structures[id];
