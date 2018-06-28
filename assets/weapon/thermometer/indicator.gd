extends Spatial

# Exports
export var indicator_surface = -1;

# Nodes
onready var indicator = $indicator;
onready var mesh = $Armature/Skeleton/thermometer;
onready var temp_label = $indicator/indicator/label_temp;
onready var unit_label = $indicator/indicator/label_unit;

# Variables
var surface_material;

func _ready():
	if (mesh && indicator_surface >= 0):
		surface_material = mesh.get_surface_material(indicator_surface);
	
	if (surface_material && indicator):
		surface_material.albedo_texture = indicator.get_texture();
		update_indicator(0.0);

func update_indicator(temp):
	if (temp_label):
		temp_label.text = str(temp).pad_decimals(1);

func toggle_lcd():
	if (temp_label && unit_label):
		temp_label.visible = !temp_label.visible;
		unit_label.visible = temp_label.visible;
		
		if (temp_label.visible):
			update_indicator(0.0);
