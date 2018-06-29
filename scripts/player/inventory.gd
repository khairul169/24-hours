extends Node

# Node
onready var player = get_parent();
onready var inventory_ui = get_node("../interface/inventory");
onready var space_state = player.get_world().direct_space_state;
onready var item_picker = get_node("../item_picker");
onready var weapon = get_node("../weapon");

# Variables
var capacity = 0.0;
var items = [];
var cur_capacity = 0.0;
var drop_queue = [];
var item_used = null;

# Weapon identifier
var weapon_hand;
var weapon_thermometer;

# State
var next_think = 0.0;

func _ready():
	# Register weapon
	weapon_hand = weapon.register_weapon("res://scripts/weapon/weapon_hand.gd");
	weapon_thermometer = weapon.register_weapon("res://scripts/weapon/weapon_thermometer.gd");
	
	capacity = 0.0;
	items.clear();
	cur_capacity = 0.0;
	next_think = 0.0;
	call_deferred("unequip_item");

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
	if (amount <= 0):
		return;
	
	var append_item = -1;
	for i in range(items.size()):
		if (items[i].id == item_id && items[i].amount < item_database.get_item_maxstack(item_id)):
			append_item = i;
			break;
		continue;
	
	var max_stack = item_database.get_item_maxstack(item_id);
	if (append_item > -1):
		var amount_filled = items[append_item].amount + amount;
		if (amount_filled > max_stack):
			items[append_item].amount = max_stack;
			_add_item_stacks(item_id, amount_filled - max_stack);
		else:
			items[append_item].amount += amount;
	else:
		if (amount > max_stack):
			_add_item_stacks(item_id, max_stack);
			_add_item_stacks(item_id, amount - max_stack);
		else:
			items.append({"id": item_id, "amount": amount});

func remove_item(slot_id, count = 1):
	if (slot_id < 0 || slot_id >= items.size()):
		return false;
	
	if (item_used == slot_id && item_database.is_item_usable(items[slot_id].id)):
		unequip_item();
	
	if (items[slot_id].amount > 1):
		items[slot_id].amount -= count;
		
		if (items[slot_id].amount <= 0):
			items.remove(slot_id);
	else:
		items.remove(slot_id);
	
	# Update inventory
	update_item();
	return true;

func get_item_id(slot_id):
	if (slot_id < 0 || slot_id >= items.size()):
		return 0;
	return items[slot_id].id;

func get_item_amount(slot_id):
	if (slot_id < 0 || slot_id >= items.size()):
		return 0;
	return items[slot_id].amount;

func use_item(slot_id):
	if (slot_id < 0 || slot_id >= items.size()):
		return;
	
	# Dequip equipped item
	if (slot_id == item_used):
		unequip_item();
		return;
	
	# Item is not usable
	var item_id = items[slot_id].id;
	if (!item_database.is_item_usable(item_id)):
		return;
	
	# Foods
	if (item_database.foods.has(item_id)):
		consume_food(slot_id);
		return;
	
	# Drinks
	if (item_database.drinks.has(item_id)):
		consume_drinks(slot_id);
		return;
	
	# Thermometer
	if (item_id == item_database.ITEM_THERMOMETER):
		item_used = slot_id;
		weapon.set_current_weapon(weapon_thermometer);
	
	# Close all window interface
	player.interface.hide_all();

func unequip_item():
	item_used = null;
	weapon.set_current_weapon(weapon_hand);

func drop_item(slot_id, amount):
	if (slot_id < 0 || slot_id >= items.size() || amount <= 0):
		return;
	drop_queue.append([slot_id, amount]);

func _queue_drop():
	for i in range(drop_queue.size()):
		var slot_id = drop_queue[i][0];
		var drop_amount = drop_queue[i][1];
		
		for i in range(drop_amount):
			var pos = player.global_transform.origin + (Vector3(rand_range(-1, 1), 0, rand_range(-1, 1)) * 0.5);
			var normal = Vector3(0, 1, 0);
			
			# Prevent items from intersecting each other
			var exclusion = [player];
			for i in get_tree().get_nodes_in_group("pickable_items"):
				if (pos.distance_to(i.global_transform.origin) < 5.0):
					exclusion.append(i);
			
			# Cast a ray
			var ray_result = space_state.intersect_ray(pos + Vector3(0, 3.0, 0), pos - Vector3(0, 3.0, 0), exclusion);
			if (ray_result != null && !ray_result.empty()):
				pos.y = ray_result.position.y;
				normal = ray_result.normal.normalized();
			
			# Instance item
			spawn_item(items[slot_id].id, pos, normal);
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

func spawn_item(id, pos, normal):
	if (!item_database.is_item_valid(id)):
		return;
	
	var item_scene = item_database.get_item_scene(id);
	if (!item_scene):
		return;
	
	# Instance scene
	var instance = item_scene.instance();
	player.scene.add_child(instance);
	
	# Set object transform
	instance.transform = instance.transform.looking_at(normal, Vector3(0, 1, 0));
	instance.transform = instance.transform.rotated(normal, deg2rad(randi() % 360));
	instance.global_transform.origin = pos;

func consume_food(id):
	var value = item_database.foods[items[id].id];
	player.hunger = clamp(player.hunger + value, 0.0, 1.0);
	remove_item(id, 1);

func consume_drinks(id):
	var value = item_database.drinks[items[id].id];
	player.thirst = clamp(player.thirst + value, 0.0, 1.0);
	remove_item(id, 1);
