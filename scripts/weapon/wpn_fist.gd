extends "res://gfps/scripts/weapon/base_weapon.gd"

func _init():
	# Weapon name
	name = "Fist";
	
	# Resources
	view_scene = "res://assets/weapon/fist/weapon_fist.tscn";
	
	# Weapon stats
	clip = 0;
	ammo = 0;
	move_speed = 1.0;
	damage = 16.0;
	recoil = Vector2();
	spread = Vector2();
	
	firing_delay = 0.6;
	firing_range = 3.0;
	firing_mode = MODE_SINGLE;
	can_aim = false;
