extends StaticBody

# Exports
export var campfire_range = 5.0;

# Variables
var next_burn = 0.0;
var fuels = {'item_id': 0, 'amount': 0};

func _ready():
	toggle_fire(false);
	add_to_group("campfire");

func _process(delta):
	if (next_burn > 0.0):
		next_burn = max(next_burn - delta, 0.0);
		
		if (next_burn <= 0.0):
			if (fuels.amount > 0):
				toggle_fire(true);
				next_burn += item_database.usable_fuels[fuels.item_id];
				fuels.amount -= 1;
			else:
				toggle_fire(false);
				fuels.item_id = 0;
				fuels.amount = 0;

func fuel_compatible(item_id):
	return ((fuels.item_id <= 0 || fuels.item_id == item_id) && item_database.usable_fuels.has(item_id));

func add_fuel(item_id, amount):
	if (!item_database.usable_fuels.has(item_id) || amount <= 0):
		return;
	
	if (next_burn <= 0.0):
		next_burn += item_database.usable_fuels[item_id];
		fuels.item_id = item_id;
		fuels.amount = amount-1;
		toggle_fire(true);
	else:
		fuels.item_id = item_id;
		fuels.amount += amount;

func toggle_fire(enable):
	if (enable):
		$AnimationPlayer.play("idle");
		$particle1.show();
		$particle2.show();
	else:
		$AnimationPlayer.play("terminated");
		$particle1.hide();
		$particle2.hide();
	
	$particle1.emitting = enable;
	$particle2.emitting = enable;

func get_estimation():
	var est = next_burn;
	if (fuels.item_id > 0 && item_database.usable_fuels.has(fuels.item_id)):
		est += fuels.amount * item_database.usable_fuels[fuels.item_id];
	return est;

func is_emitting():
	return next_burn > 0.0;
