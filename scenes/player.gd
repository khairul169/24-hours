extends "res://gfps/scripts/player/controller.gd"

func _ready():
	# Enable character sprinting
	can_sprint = true;

func _input(event):
	if (event is InputEventMouseButton):
		if ($weapon && event.button_index == BUTTON_LEFT):
			$weapon.input['attack'] = event.pressed;
		
		if ($weapon && event.button_index == BUTTON_RIGHT):
			$weapon.input['special'] = event.pressed;

func _physics_process(delta):
	# Update player input
	input['forward'] = Input.is_key_pressed(KEY_W);
	input['backward'] = Input.is_key_pressed(KEY_S);
	input['left'] = Input.is_key_pressed(KEY_A);
	input['right'] = Input.is_key_pressed(KEY_D);
	
	input['jump'] = Input.is_key_pressed(KEY_SPACE);
	input['sprint'] = Input.is_key_pressed(KEY_SHIFT);
