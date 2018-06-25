extends Node

# Node
onready var player = get_parent();

# Variables
var capacity = 0.0;
var items = [];
var cur_capacity = 0.0;

# State
var next_think = 0.0;

func reset():
	capacity = 0.0;
	items.clear();
	cur_capacity = 0.0;
	next_think = 0.0;

func _ready():
	reset();

func _process(delta):
	next_think -= delta;
	
	if (next_think <= 0.0):
		next_think = 1.0;
		calculate_capacity();

func add_item(item_id, amount = 1):
	if (item_database.is_item_stackable(item_id)):
		_add_item_stacks(item_id, amount);
	else:
		for i in range(amount):
			items.append({"id": item_id, "amount": 1});
	
	# Recalculate inventory capacity
	calculate_capacity();

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

func remove_item(slot_id, count = 1):
	if (slot_id < 0 || slot_id >= items.size()):
		return;
	if (count > items[slot_id].amount):
		items[slot_id].amount -= count;
		
		if (items[slot_id].amount <= 0):
			items.remove(slot_id);
	else:
		items.remove(slot_id);
	
	# Recalculate inventory capacity
	calculate_capacity();

func use_item(slot_id):
	if (slot_id < 0 || slot_id >= items.size()):
		return;
	if (!item_database.is_item_usable(items[slot_id].id)):
		return;

func is_over_capacity():
	return cur_capacity > capacity;

func calculate_capacity():
	capacity = 3.0;
	capacity += clamp((player.temperature - 34.0) / 3.0 * 3.0, 0.0, 3.0);
	capacity += clamp(player.hunger * 2.0, 0.0, 2.0);
	capacity += clamp(player.thirst * 2.0, 0.0, 2.0);
	
	cur_capacity = 0.0;
	for i in items:
		cur_capacity += item_database.get_item_weight(i.id) * i.amount;
