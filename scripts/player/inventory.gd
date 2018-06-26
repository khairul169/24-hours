extends Node

# Node
onready var player = get_parent();
onready var inventory_ui = get_node("../interface/inventory");
onready var space_state = player.get_world().direct_space_state;
onready var item_picker = get_node("../item_picker");

# Variables
var capacity = 0.0;
var items = [];
var cur_capacity = 0.0;
var drop_queue = [];

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

func _physics_process(delta):
	if (drop_queue.size() > 0):
		_queue_drop();

func add_item(item_id, amount = 1):
	if (!item_database.is_item_valid(item_id)):
		return;
	if (item_database.is_item_stackable(item_id)):
		_add_item_stacks(item_id, amount);
	else:
		for i in range(amount):
			items.append({"id": item_id, "amount": 1});
	
	# Update inventory
	update_item();

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
	if (items[slot_id].amount > 1):
		items[slot_id].amount -= count;
		
		if (items[slot_id].amount <= 0):
			items.remove(slot_id);
	else:
		items.remove(slot_id);
	
	# Update inventory
	update_item();

func get_item_amount(slot_id):
	if (slot_id < 0 || slot_id >= items.size()):
		return 0;
	return items[slot_id].amount;

func use_item(slot_id):
	if (slot_id < 0 || slot_id >= items.size()):
		return;
	if (!item_database.is_item_usable(items[slot_id].id)):
		return;

func drop_item(slot_id, amount):
	if (slot_id < 0 || slot_id >= items.size() || amount <= 0):
		return;
	drop_queue.append([slot_id, amount]);

func _queue_drop():
	for i in range(drop_queue.size()):
		var slot_id = drop_queue[i][0];
		var drop_amount = drop_queue[i][1];
		
		for i in range(drop_amount):
			var pos = player.global_transform.origin + (Vector3(rand_range(-1, 1), 0, rand_range(-1, 1)) * 1.0);
			var ray_result = space_state.intersect_ray(pos + Vector3(0, 5.0, 0), pos - Vector3(0, 5.0, 0), [player]);
			if (ray_result != null && !ray_result.empty()):
				pos.y = ray_result.position.y;
			
			spawn_item(items[slot_id].id, pos);
			remove_item(slot_id, 1);
		
		# Remove queue
		drop_queue.remove(i);
	
	# Update inventory
	item_picker.check_near_item();
	inventory_ui.refresh_items();

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

func update_item():
	capacity = 3.0;
	capacity += clamp((player.temperature - 34.0) / 3.0 * 3.0, 0.0, 3.0);
	capacity += clamp(player.hunger * 2.0, 0.0, 2.0);
	capacity += clamp(player.thirst * 2.0, 0.0, 2.0);
	
	cur_capacity = 0.0;
	for i in items:
		cur_capacity += item_database.get_item_weight(i.id) * i.amount;
	
	inventory_ui.refresh_items();

func spawn_item(id, pos):
	if (!item_database.is_item_valid(id)):
		return;
	
	var item_scene = item_database.get_item_scene(id);
	if (!item_scene):
		return;
	
	# Instance scene
	var instance = item_scene.instance();
	player.scene.add_child(instance);
	
	# Set object transform
	instance.global_transform.origin = pos;
	instance.rotation_degrees.y = randf() * 360.0;
