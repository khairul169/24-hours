extends StaticBody

# Exports
export var campfire_range = 5.0;

# Variables
var next_burn = 0.0;
var fuels = [];

func _ready():
	toggle_fire(false);
	add_to_group("campfire");

func _process(delta):
	if (next_burn > 0.0):
		next_burn = max(next_burn - delta, 0.0);
		
		if (next_burn <= 0.0):
			if (fuels.size() > 0):
				add_fuel(fuels[0]);
				fuels.remove(0);
			else:
				toggle_fire(false);

func add_fuel(item_id):
	if (next_burn <= 0.0):
		if (item_database.usable_fuels.has(item_id)):
			next_burn += item_database.usable_fuels[item_id];
			toggle_fire(true);
	else:
		fuels.append(item_id);

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
	for i in fuels:
		if (item_database.usable_fuels.has(i)):
			est += item_database.usable_fuels[i];
	return est;

func is_emitting():
	return next_burn > 0.0;
