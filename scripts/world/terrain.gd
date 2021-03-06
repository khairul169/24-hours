extends Spatial

const TerrainGenerator = preload("terrain_generator.gd");

export var seeds = 0;
export (Material) var terrain_material;
export (NodePath) var player_node;
export (PackedScene) var water_scene;
export (PackedScene) var rocks_scene;
export (Array) var tree_scenes;
export (Mesh) var grass_mesh;
export (Material) var grass_material;
export (PackedScene) var bush_scene;

signal chunks_updated(chunks);

# Grass type
enum {
	GRASS_DEFAULT = 0,
	GRASS_BUSH
};

# World space state
onready var space_state = get_world().direct_space_state;
onready var player = get_parent().get_node("player");

# Variables
var player_pos = Vector3();
var current_chunk = [0, 0];
var active_chunks = {};
var chunk_size = 50.0;
var chunk_distance = 3;
var terrain_height = 64.0;
var terrain_size = 16.0;
var rocks_intensity = 0.1;
var tree_intensity = 0.6;
var grass_intensity = 0.65;

var thread = Thread.new();
var terrain = TerrainGenerator.new();

func _ready():
	if (player_node):
		player_node = get_node(player_node);
	
	seed(seeds);
	terrain.set_seed(seeds);
	terrain.set_terrain_size(terrain_size, terrain_height);
	
	if (player_node):
		player_pos = player_node.global_transform.origin;
		# Find spawn point
		for i in range(10):
			var pos = player_pos + Vector3(rand_range(-500.0, 500.0), 0, rand_range(-500.0, 500.0));
			var h = terrain.get_height_at(pos);
			if (h < 2.0):
				continue;
			pos.y = h;
			player_pos = pos;
			break;
		
		player_pos.y += 1.0;
		player_node.global_transform.origin = player_pos;
		current_chunk = chunk_from_pos(player_pos);
	
	# Build world
	generate_world(current_chunk);

func _physics_process(delta):
	if (player_node):
		player_pos = player_node.global_transform.origin;
	
	var player_chunk = chunk_from_pos(player_pos);
	if ((current_chunk[0] != player_chunk[0] || current_chunk[1] != player_chunk[1]) && !thread.is_active()):
		thread.start(self, "generate_world", player_chunk, Thread.PRIORITY_HIGH);

func generate_world(chunk):
	var new_chunks = {};
	var sz = 1 + (2 * (chunk_distance - 1));
	
	for i in range(sz):
		for j in range(sz):
			var x = j - (chunk_distance - 1) + chunk[0];
			var y = i - (chunk_distance - 1) + chunk[1];
			var node_name = get_chunk_name(x, y);
			new_chunks[node_name] = [x, y];
	
	for i in get_children():
		if (!new_chunks.has(i.name)):
			i.call_deferred("queue_free");
	
	for i in new_chunks.keys():
			if (!has_node(i)):
				var chunk_pos = chunk_from_name(i);
				var position = Vector3(chunk_pos[0], 0, chunk_pos[1]) * chunk_size;
				load_chunk(i, position);
	
	call_deferred("update_chunk", chunk, new_chunks);
	return true;

func get_chunk_name(x, y):
	return str(x, "_", y);

func chunk_from_name(name):
	return str(name).split("_");

func chunk_from_pos(pos):
	return [int(floor(pos.x / chunk_size)), int(floor(pos.z / chunk_size))];

func update_chunk(chunk, new_chunks):
	if (thread.is_active()):
		thread.wait_to_finish();
	
	# Set current chunk
	current_chunk = chunk;
	active_chunks = new_chunks;
	emit_signal("chunks_updated", new_chunks);

func load_chunk(name, position):
	# Create chunk
	var chunk = Spatial.new();
	chunk.name = name;
	chunk.transform.origin = position;
	add_child(chunk, true);
	
	var outpost = null;
	if (randf() <= 0.2):
		var size = int(rand_range(chunk_size * 0.25, chunk_size * 0.4));
		outpost = {
			'position': Vector3(1, 0, 1) * (chunk_size) * 0.5,
			'size': size
		};
	
	# Generate heightmap terrain mesh
	var terrain_mesh = terrain.generate_mesh(position, chunk_size, 5.0, outpost);
	
	# Create terrain mesh instance
	create_terrain(chunk, terrain_mesh);
	
	# Create props
	call_deferred("create_water", chunk);
	call_deferred("create_outpost", chunk, outpost);
	call_deferred("create_rocks", chunk);
	
	# Terrain vegetation
	var veg = Spatial.new();
	veg.name = "vegetation";
	chunk.add_child(veg);
	load_vegetation(chunk, veg, outpost);

func create_terrain(node, mesh):
	if (!mesh):
		return;
	var instance = MeshInstance.new();
	instance.name = "terrain";
	node.add_child(instance, true);
	instance.hide();
	instance.mesh = mesh;
	instance.create_trimesh_collision();
	call_deferred("configure_terrain", instance);

func configure_terrain(instance):
	if (!instance):
		return;
	instance.material_override = terrain_material;
	instance.cast_shadow = GeometryInstance.SHADOW_CASTING_SETTING_OFF;
	instance.show();

func create_water(node):
	if (!node || !water_scene):
		return;
	
	var instance = water_scene.instance();
	instance.name = "water";
	instance.scale = Vector3(chunk_size, 1, chunk_size);
	node.add_child(instance);

func create_outpost(node, outpost):
	if (!node || !space_state || !outpost):
		return;
	
	var outpos_position = node.global_transform.origin + outpost.position;
	var ray = space_state.intersect_ray(outpos_position + Vector3(0, terrain_height, 0), outpos_position - Vector3(0, terrain_height, 0), [player]);
	if (ray.size() > 0):
		outpos_position.y = ray.position.y;
	
	if (outpos_position.y < 0.0 || outpos_position.y > terrain_height * 0.5):
		return;
	
	var instance = preload("res://assets/outpost/outpost01/outpost01.tscn").instance();
	instance.name = "outpost";
	node.add_child(instance, true);
	
	# Set outpost transform
	instance.global_transform.origin = outpos_position;
	instance.rotation = Vector3(0, 1, 0) * randf() * 2.0 * PI;
	
	for i in instance.get_children():
		if (!i is MeshInstance):
			continue;
		
		var pos = i.global_transform.origin;
		ray = space_state.intersect_ray(pos + Vector3(0, terrain_height, 0), pos - Vector3(0, terrain_height, 0), [player, i]);
		if (ray.size() > 0):
			pos.y = ray.position.y;
		
		# Set the position
		i.global_transform.origin = pos;

func create_rocks(chunk):
	if (!rocks_scene || !space_state):
		return;
	
	var start_pos = chunk.global_transform.origin;
	var instance_count = randi() % int(chunk_size * rocks_intensity);
	for i in range(instance_count):
		var pos = start_pos + Vector3(randf() * chunk_size, 0, randf() * chunk_size);
		var ray = space_state.intersect_ray(pos + Vector3(0, terrain_height, 0), pos - Vector3(0, terrain_height, 0), [player]);
		if (ray.size() > 0):
			pos.y = ray.position.y;
		if (pos.y < 0.0):
			continue;
		
		var instance = rocks_scene.instance();
		chunk.add_child(instance);
		instance.global_transform.origin = pos;
		instance.rotation = Vector3(0, 1, 0) * randf() * 2 * PI;
		instance.scale = Vector3(1, 1, 1) * rand_range(1.0, 3.2);

func load_vegetation(chunk, parent, outpost):
	if (!space_state):
		return;
	
	var start_pos = parent.global_transform.origin;
	var tree_amount = randi() % int(chunk_size * tree_intensity);
	
	for i in range(tree_amount):
		var pos = start_pos + Vector3(randf() * chunk_size, 0, randf() * chunk_size);
		var ray = space_state.intersect_ray(pos + Vector3(0, terrain_height, 0), pos - Vector3(0, terrain_height, 0), [player]);
		if (ray.size() > 0):
			pos.y = ray.position.y;
		else:
			continue;
		
		if (outpost && Vector3(pos.x - start_pos.x, 0.0, pos.z - start_pos.z).distance_to(outpost.position) < outpost.size):
			continue;
		
		# Spawn height level
		if (pos.y > terrain_height - 5.0 || pos.y < 2.0 || ray.normal.dot(Vector3(0, 1, 0)) < 0.9):
			continue;
		
		call_deferred("create_tree", parent, pos);
	
	var grass_chunk_num = 2;
	var grass_chunk_size = chunk_size / float(grass_chunk_num);
	
	for i in range(grass_chunk_num):
		for j in range(grass_chunk_num):
			var pos = Vector3(i, 0, j) * grass_chunk_size;
			load_grass_instance(parent, pos, grass_chunk_size, outpost);

func create_tree(node, position):
	if (!tree_scenes || !node || !node.is_inside_tree()):
		return;
	
	var instance = tree_scenes[randi() % tree_scenes.size()].instance();
	instance.name = "tree";
	node.add_child(instance, true);
	
	instance.global_transform.origin = position;
	instance.rotation_degrees = Vector3(0, randf() * 360.0, 0);
	instance.scale = Vector3(1, 1, 1) * rand_range(0.8, 1.6);

func load_grass_instance(node, position, size, outpost):
	var grass_instance_num = int(chunk_size * chunk_size * grass_intensity);
	var start_pos = node.global_transform.origin + position;
	var grass_instances = [];
	
	for i in range(grass_instance_num):
		var pos = start_pos + Vector3(randf(), 0, randf()) * size;
		var parent_pos = node.global_transform.origin;
		if (outpost && Vector3(pos.x - parent_pos.x, 0.0, pos.z - parent_pos.z).distance_to(outpost.position) < outpost.size && randf() > 0.1):
			continue;
		
		var ray = space_state.intersect_ray(pos + Vector3(0, terrain_height, 0), pos - Vector3(0, terrain_height, 0), [player]);
		if (ray.size() > 0):
			if (!ray.collider.get_parent().name.begins_with("terrain")):
				continue;
			if (ray.normal.dot(Vector3(0, 1, 0)) < 0.9):
				continue;
			pos.y = ray.position.y;
		else:
			continue;
		
		if (pos.y < 2.0):
			continue;
		
		# Grass type
		var type = GRASS_DEFAULT;
		if (randf() < 0.01):
			type = GRASS_BUSH;
		
		# Add instance
		grass_instances.append({'pos': pos - start_pos, 'type': type});
	
	# Call on main thread
	call_deferred("create_grass", node, position, grass_instances);

func create_grass(node, position, instances):
	if (!node || !grass_mesh):
		return;
	
	var grass_instance = MultiMeshInstance.new();
	grass_instance.name = "grass_instance";
	grass_instance.transform.origin = position;
	
	var grass_multimesh = MultiMesh.new();
	grass_multimesh.mesh = grass_mesh;
	grass_multimesh.color_format = MultiMesh.COLOR_8BIT;
	grass_multimesh.transform_format = MultiMesh.TRANSFORM_3D;
	
	grass_instance.multimesh = grass_multimesh;
	grass_instance.material_override = grass_material;
	grass_instance.cast_shadow = MeshInstance.SHADOW_CASTING_SETTING_OFF;
	node.add_child(grass_instance, true);
	
	# Default grass position
	var grass_default = PoolVector3Array();
	var bushes_count = 0;
	
	# Get instance type
	for i in range(instances.size()):
		var grass_data = instances[i];
		if (grass_data.type == GRASS_DEFAULT):
			grass_default.append(grass_data.pos);
		
		if (grass_data.type == GRASS_BUSH && bush_scene && bushes_count < 5):
			bushes_count += 1;
			var bush = bush_scene.instance();
			node.add_child(bush);
			bush.transform.origin = position + grass_data.pos;
			bush.scale = Vector3(1, 1, 1) * rand_range(0.9, 1.4);
	
	# Set multimesh instance size
	grass_multimesh.instance_count = grass_default.size();
	
	# Set multimesh transforms
	for i in range(grass_default.size()):
		var tr = Transform();
		tr = tr.scaled(Vector3(1, 1, 1) * (0.6 + randf() * 1.2));
		tr.origin = grass_default[i];
		grass_multimesh.set_instance_transform(i, tr);
		
		if (randf() > 0.6):
			grass_multimesh.set_instance_color(i, Color(1, 0, 0));
		else:
			grass_multimesh.set_instance_color(i, Color(0, 0, 0));
