extends "res://gfps/scripts/weapon/base_weapon.gd"

func _init():
	# Item data
	name = "Hand";
	view_scene = "res://assets/weapon/hand/weapon_hand.tscn";

func pick_animation():
	if (PlayerWeapon.next_think > 0.0):
		return;
	
	PlayerWeapon.play_animation("pick", false, 0.1);
	PlayerWeapon.next_think = 0.2;
	PlayerWeapon.next_idle = 0.4;
