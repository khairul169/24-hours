extends StaticBody

enum STORAGE_TYPE {
	EMPTY = 0,
	FOODS,
	STICK,
	
	MAX_NUM
};

signal item_updated();

var is_opened = false;
var items = [];

func _ready():
	is_opened = false;
	
	# Randomize storage type
	var storage_type = randi() % STORAGE_TYPE.MAX_NUM;
	
	if (storage_type == FOODS):
		add_item(item_database.ITEM_CANNED_TUNA, 1 + randi() % 2);
		add_item(item_database.ITEM_BOTTLED_WATER, 1 + randi() % 3);
	
	if (storage_type == STICK):
		add_item(item_database.ITEM_STICK, 4 + randi() % 8);

func remove_item(id, amount = 1):
	if (id < 0 || id >= items.size()):
		return false;
	
	items[id].amount -= amount;
	if (items[id].amount <= 0):
		items.remove(id);
	
	emit_signal("item_updated");
	return true;

func add_item(item_id, amount = 1):
	if (!item_database.is_item_valid(item_id)):
		return false;
	
	var item_stack = -1;
	var max_stack = item_database.get_item_maxstack(item_id);
	
	for i in range(items.size()):
		if (max_stack <= 1):
			break;
		if (items[i].amount >= max_stack):
			continue;
		if (items[i].item_id == item_id):
			item_stack = i;
	
	# Has stack
	if (item_stack >= 0 && item_stack < items.size()):
		var total = items[item_stack].amount + amount;
		if (total <= max_stack):
			items[item_stack].amount += amount;
		else:
			items[item_stack].amount = max_stack;
			add_item(item_id, total - max_stack);
	else:
		if (amount > max_stack):
			add_item(item_id, max_stack);
			add_item(item_id, amount - max_stack);
		else:
			items.append({'item_id': item_id, 'amount': amount});
	
	emit_signal("item_updated");
	return true;

func get_item(id):
	if (id < 0 || id >= items.size()):
		return null;
	return items[id];
