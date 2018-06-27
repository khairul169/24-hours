extends "res://gfps/scripts/player/controller.gd"

const MIN_TEMP = 32.8;
const MAX_TEMP = 36.9;

# Nodes
onready var scene = get_parent();
onready var inventory = $inventory;
onready var item_picker = $item_picker;
onready var weapon = $weapon;

# Variables
var health = 0.0;
var temperature = 0.0;
var hunger = 0.0;
var thirst = 0.0;

# State
var next_step = 0.0;
var last_time = 0.0;
var next_check = 0.0;
var near_firesrc = false;

var wpn_fist;

func _init():
	# Initialize character
	can_sprint = true;

func _ready():
	# Setup controller
	camera_rotation.x = 0.0;
	
	# Reset stats
	randomize();
	health = rand_range(90.0, 100.0);
	temperature = rand_range(36.4, MAX_TEMP);
	hunger = rand_range(0.7, 0.85);
	thirst = rand_range(0.6, 0.8);
	next_step = 0.0;
	last_time = scene.game_time;
	next_check = 0.0;
	near_firesrc = false;
	
	# Register weapon
	wpn_fist = weapon.register_weapon("res://scripts/weapon/wpn_fist.gd");
	
	# Set current item
	inventory.using_item = null;
	weapon.set_current_weapon(wpn_fist);
	
	# Give default item
	inventory.add_item(item_database.ITEM_STICK, int(rand_range(8.0, 14.0)));

func _input(event):
	if (event is InputEventMouseButton):
		if (weapon && event.button_index == BUTTON_LEFT):
			weapon.input.attack = event.pressed;
		
		if (weapon && event.button_index == BUTTON_RIGHT):
			weapon.input.special = event.pressed;

func _physics_process(delta):
	# Update player input
	input.forward = Input.is_key_pressed(KEY_W);
	input.backward = Input.is_key_pressed(KEY_S);
	input.left = Input.is_key_pressed(KEY_A);
	input.right = Input.is_key_pressed(KEY_D);
	input.jump = Input.is_key_pressed(KEY_SPACE);
	input.sprint = Input.is_key_pressed(KEY_SHIFT);

func _process(delta):
	next_step -= delta;
	if (next_step <= 0.0):
		next_step = 0.1;
		update_stats(delta);
	
	if (next_check < scene.game_time):
		next_check = fmod(scene.game_time + 4.0, 24.0);
		check_stats();

func update_stats(delta):
	# Delta time in game time
	var timecycle_delta = scene.game_time - last_time;
	if (timecycle_delta < 0.0):
		timecycle_delta = (scene.game_time + 24.0) - last_time;
	last_time = scene.game_time;
	
	# Day
	var temp_factor = 0.8;
	if (scene.game_time >= 10.0 && scene.game_time < 14.0):
		temp_factor *= 1.8;
	
	# Night
	if (scene.game_time >= 18.0 || scene.game_time < 6.0):
		temp_factor = -1.8;
	if (scene.game_time >= 22.0 || scene.game_time < 4.0):
		temp_factor *= 2.0;
	
	# Keep body temperature at the minimal level
	if (temperature < MIN_TEMP):
		temp_factor = 1.0;
	
	# Burn energy to produce heat
	if (hunger > 0.4):
		temp_factor += (hunger - 0.4) / 0.6 * 2.2;
	
	# Check if player near a fire source
	near_firesrc = false;
	for i in get_tree().get_nodes_in_group("campfire"):
		if (global_transform.origin.distance_to(i.global_transform.origin) > i.campfire_range):
			continue;
		if (!i.has_method("is_emitting") || !i.is_emitting()):
			continue;
		near_firesrc = true;
		break;
	
	if (near_firesrc):
		temp_factor = 0.4 + clamp(36.4 - temperature * 1.8, 0.0, 2.0);
	
	if (temperature > 36.8 || (temperature > 35.6 && health < 40.0)):
		temp_factor = -0.4;
	
	# Update temperature
	temperature = clamp(temperature + (timecycle_delta * temp_factor), MIN_TEMP, MAX_TEMP);
	
	var hunger_factor = 0.083;
	if (temperature < 35.0):
		hunger_factor *= 1.2;
	if (is_sprinting):
		hunger_factor *= 2.0;
	hunger = clamp(hunger - (timecycle_delta * hunger_factor), 0.0, 1.0);
	
	var thirst_factor = 0.125;
	if (!is_moving):
		thirst_factor *= 0.6;
	if (is_sprinting):
		thirst_factor *= 4.8;
	thirst = clamp(thirst - (timecycle_delta * thirst_factor), 0.0, 1.0);
	
	# Disable some ability if player are in weak state
	if (inventory.is_over_capacity() || temperature <= 33.0 || hunger <= 0.0 || thirst < 0.1):
		can_jump = false;
		can_sprint = false;
	else:
		can_jump = true;
		can_sprint = true;

func check_stats():
	if (temperature < 34.0): # Hypothermia
		health -= rand_range(12.0, 18.0);
	
	if (hunger <= 0.0): # Hungry
		health -= rand_range(6.0, 12.0);
	
	if (thirst <= 0.0): # Thirsty
		health -= rand_range(8.0, 15.0);
	
	health = clamp(health, 0.0, 100.0);
