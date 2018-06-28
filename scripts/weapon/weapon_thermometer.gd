extends "res://gfps/scripts/weapon/base_weapon.gd"

# Variables
var examining = false;
var next_update = 0.0;

func _init():
	# Item data
	name = "Thermometer";
	view_scene = "res://assets/weapon/thermometer/thermometer.tscn";

func _update_indicator(temp):
	if (!PlayerWeapon.weapon_node):
		return;
	if (PlayerWeapon.weapon_node.has_method("update_indicator")):
		PlayerWeapon.weapon_node.update_indicator(temp);

func _toggle_lcd():
	if (!PlayerWeapon.weapon_node):
		return;
	if (PlayerWeapon.weapon_node.has_method("toggle_lcd")):
		PlayerWeapon.weapon_node.toggle_lcd();

func attach():
	.attach();
	examining = false;

func attack():
	if (PlayerWeapon.next_think > 0.0):
		return;
	
	PlayerWeapon.play_animation("examine", false, 0.1);
	PlayerWeapon.next_think = 1.25;
	PlayerWeapon.next_idle = 1.25;
	examining = true;
	return false;

func think(delta):
	.think(delta);
	
	if (next_update > 0.0):
		next_update -= delta;
	
	if (PlayerWeapon.next_think > 0.0 || !examining):
		return;
	
	# Set new temperature
	var player = PlayerWeapon.controller;
	_update_indicator(player.temperature);
	
	# Unequip item
	player.inventory.unequip_item();
	examining = false;

func special():
	if (next_special > 0.0):
		return;
	
	_toggle_lcd();
	next_special = 0.5;
