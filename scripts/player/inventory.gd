extends Node

var capacity = 0.0;
var items = [];
var cur_capacity = 0.0;

func reset():
	capacity = 0.0;
	items.clear();
	cur_capacity = 0.0;

func _ready():
	reset();
	
	add_item(item_database.ITEM_STICK, 10);
	add_item(item_database.ITEM_STICK, 40);
	add_item(item_database.ITEM_BRANCH, 1);
	add_item(item_database.ITEM_BRANCH, 3);

func add_item(item_id, amount = 1):
	if (item_database.is_item_stackable(item_id)):
		_add_item_stacks(item_id, amount);
	else:
		for i in range(amount):
			items.append({"id": item_id, "amount": 1});

func _add_item_stacks(item_id, amount):
	var append_item = -1;
	for i in range(items.size()):
		if (items[i].id == item_id && items[i].amount < item_database.get_item_maxstack(item_id)):
			append_item = i;
			break;
		continue;
	
	if (append_item > -1):
		var max_stack = item_database.get_item_maxstack(item_id);
		var amount_filled = items[append_item].amount + amount;
		if (amount_filled > max_stack):
			var exceeded_amount = amount_filled - max_stack;
			items[append_item].amount = max_stack;
			items.append({"id": item_id, "amount": exceeded_amount});
		else:
			items[append_item].amount += amount;
	else:
		items.append({"id": item_id, "amount": amount});

func remove_item(slot_id):
	if (slot_id < 0 || slot_id >= items.size()):
		return;
	items.remove(slot_id);

func use_item(slot_id):
	if (slot_id < 0 || slot_id >= items.size()):
		return;
	if (!item_database.is_item_usable(items[slot_id].id)):
		return;

func is_over_capacity():
	return cur_capacity > capacity;
