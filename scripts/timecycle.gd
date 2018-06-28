extends Node

export (NodePath) var worldenv;
export (NodePath) var sun_node;
export (ProceduralSky) var sky;
export var update_delay = 0.01;

# Node
onready var scene = get_parent();

# Variables
var next_step = 0.0;

# Sky colors
var day_color = {
	'top': Color(0.4, 0.5, 0.65) * 0.6,
	'bot': Color(0.75, 0.8, 0.8) * 0.9,
	'light': Color(0.63, 0.61, 0.62)
};
var night_color = {
	'top': Color(0.04, 0.04, 0.1),
	'bot': Color(0.02, 0.02, 0.06),
	'light': Color(0.18, 0.17, 0.32)
};
var evening_color = {
	'top': Color(0.5, 0.45, 0.3),
	'bot': Color(0.8, 0.7, 0.5),
	'light': Color(0.4, 0.4, 0.25)
};

func _ready():
	worldenv = get_node(worldenv);
	sun_node = get_node(sun_node);
	
	if (!sky):
		print("Sky is not configured!");
		sky = ProceduralSky.new();
	
	# Set sky to current env
	worldenv.environment.background_sky = sky;

func _process(delta):
	next_step = next_step - delta;
	if (next_step > 0.0):
		return;
	next_step = update_delay;
	
	# Get game time from scene
	var time = scene.game_time;
	
	# Set sun position
	var latitude = fmod(90.0 + (time / 24.0 * 360.0), 180.0);
	var longitude = 60.0;
	
	# Light intensity
	var light_int = 1.0;
	if (time >= 18.1 || time < 5.9):
		light_int = 0.2;
	if (time >= 17.9 && time < 18.0):
		light_int = lerp(1.0, 0.0, clamp((time - 17.9) / 0.1, 0.0, 1.0));
	if (time >= 18.0 && time < 18.1):
		light_int = lerp(0.0, 0.2, clamp((time - 18.0) / 0.1, 0.0, 1.0));
	if (time >= 5.9 && time < 6.0):
		light_int = lerp(0.2, 0.0, clamp((time - 5.9) / 0.1, 0.0, 1.0));
	if (time >= 6.0 && time < 6.1):
		light_int = lerp(0.0, 1.0, clamp((time - 6.0) / 0.1, 0.0, 1.0));
	
	# Sun lighting
	sun_node.rotation_degrees = Vector3(-latitude, fmod(180.0 - longitude, 360.0), 0.0);
	sun_node.light_energy = light_int;
	worldenv.environment.ambient_light_energy = clamp(light_int * 0.2, 0.0, 0.2);
	
	# Sky colors
	var top_color = day_color.top;
	var bot_color = day_color.bot;
	var light_col = day_color.light;
	
	# Night
	if (time >= 18.0 || time < 5.5):
		top_color = night_color.top;
		bot_color = night_color.bot;
		light_col = night_color.light;
	
	# Evening
	if (time >= 17.0 && time < 17.5):
		var step = clamp((time - 17.0) / 0.5, 0.0, 1.0);
		top_color = clerp(day_color.top, evening_color.top, step);
		bot_color = clerp(day_color.bot, evening_color.bot, step);
		light_col = clerp(day_color.light, evening_color.light, step);
	
	if (time >= 17.5 && time < 18.0):
		var step = clamp((time - 17.5) / 0.5, 0.0, 1.0);
		top_color = clerp(evening_color.top, night_color.top, step);
		bot_color = clerp(evening_color.bot, night_color.bot, step);
		light_col = clerp(evening_color.light, night_color.light, step);
	
	# Dawn
	if (time >= 5.5 && time < 6.0):
		var step = clamp((time - 5.5) / 0.5, 0.0, 1.0);
		top_color = clerp(night_color.top, day_color.top, step);
		bot_color = clerp(night_color.bot, day_color.bot, step);
		light_col = clerp(night_color.light, day_color.light, step);
	
	# Set sky color
	sky.sky_top_color = top_color;
	sky.sky_horizon_color = bot_color;
	sky.ground_bottom_color = bot_color;
	sky.ground_horizon_color = bot_color;
	
	# Update sun in the sky
	sky.sun_latitude = latitude;
	sky.sun_longitude = longitude;
	
	if (time > 18.0 || time < 6.0):
		sky.sun_angle_max = 20.0;
	else:
		sky.sun_angle_max = 60.0;
	
	# Set light color
	sun_node.light_color = light_col;
	worldenv.environment.ambient_light_color = light_col;
	worldenv.environment.fog_color = clerp(top_color, bot_color, 0.4);

func clerp(from, to, step):
	return from.linear_interpolate(to, step);
