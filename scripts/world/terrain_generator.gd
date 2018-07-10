extends Reference

# Ref
var noise;
var fractal;

# Variable
var _size;
var _height;

func _init():
	noise = OsnNoise.new();
	noise.set_seed(0);
	
	fractal = OsnFractalNoise.new();
	fractal.set_source_noise(noise);
	fractal.set_period(64);
	fractal.set_octaves(8);
	fractal.set_persistance(0.6);

func set_seed(seeds):
	noise.set_seed(seeds);

func set_terrain_size(size, height):
	_size = size;
	_height = height;

func get_height_clamped(pos):
	if (typeof(pos) == TYPE_VECTOR2):
		return clamp(fractal.get_noise_2dv(pos / _size), -1.0, 1.0);
	if (typeof(pos) == TYPE_VECTOR3):
		return clamp(fractal.get_noise_2dv(Vector2(pos.x, pos.z) / _size), -1.0, 1.0);
	return 0.0;

func get_height_at(pos):
	return get_height_clamped(pos) * _height;

func generate_mesh(position, size, resolution, outpost = null):
	var surface = SurfaceTool.new();
	surface.begin(Mesh.PRIMITIVE_TRIANGLES);
	surface.add_smooth_group(true);
	
	var world_pos = Vector2(position.x, position.z);
	var size_range = size / resolution;
	
	var highest = null;
	var lowest = null;
	
	for x in range(size_range):
		for y in range(size_range):
			var pos = [
				(Vector2(x    , y    ) * resolution),
				(Vector2(x + 1, y    ) * resolution),
				(Vector2(x + 1, y + 1) * resolution),
				(Vector2(x    , y + 1) * resolution)
			];
			
			var ht = [
				fractal.get_noise_2dv((world_pos + pos[0]) / _size) * _height,
				fractal.get_noise_2dv((world_pos + pos[1]) / _size) * _height,
				fractal.get_noise_2dv((world_pos + pos[2]) / _size) * _height,
				fractal.get_noise_2dv((world_pos + pos[3]) / _size) * _height
			];
			
			for i in ht:
				if (highest == null || i > highest):
					highest = i;
				if (lowest == null || i < lowest):
					lowest = i;
			
			var uv2_size = 20.0;
			
			# triangle 1
			surface.add_color(calculate_color(pos[0], outpost));
			surface.add_uv(Vector2(pos[0].x, pos[0].y));
			surface.add_uv2(Vector2(pos[0].x, pos[0].y) / uv2_size);
			surface.add_vertex(Vector3(pos[0].x, ht[0], pos[0].y));
			
			surface.add_color(calculate_color(pos[1], outpost));
			surface.add_uv(Vector2(pos[1].x, pos[1].y));
			surface.add_uv2(Vector2(pos[1].x, pos[1].y) / uv2_size);
			surface.add_vertex(Vector3(pos[1].x, ht[1], pos[1].y));
			
			surface.add_color(calculate_color(pos[2], outpost));
			surface.add_uv(Vector2(pos[2].x, pos[2].y));
			surface.add_uv2(Vector2(pos[2].x, pos[2].y) / uv2_size);
			surface.add_vertex(Vector3(pos[2].x, ht[2], pos[2].y));
			
			# triangle 2
			surface.add_color(calculate_color(pos[2], outpost));
			surface.add_uv(Vector2(pos[2].x, pos[2].y));
			surface.add_uv2(Vector2(pos[2].x, pos[2].y) / uv2_size);
			surface.add_vertex(Vector3(pos[2].x, ht[2], pos[2].y));
			
			surface.add_color(calculate_color(pos[3], outpost));
			surface.add_uv(Vector2(pos[3].x, pos[3].y));
			surface.add_uv2(Vector2(pos[3].x, pos[3].y) / uv2_size);
			surface.add_vertex(Vector3(pos[3].x, ht[3], pos[3].y));
			
			surface.add_color(calculate_color(pos[0], outpost));
			surface.add_uv(Vector2(pos[0].x, pos[0].y));
			surface.add_uv2(Vector2(pos[0].x, pos[0].y) / uv2_size);
			surface.add_vertex(Vector3(pos[0].x, ht[0], pos[0].y));
	
	surface.index();
	surface.generate_normals();
	var mesh = surface.commit();
	surface.clear();
	return mesh;

func calculate_color(pos, outpost):
	var col = Color(0, 0, 0, 0);
	if (!outpost):
		return col;
	var distance = outpost.position.distance_to(Vector3(pos.x, 0.0, pos.y));
	col.r = lerp(0.0, 1.0, clamp((outpost.size - distance) / 0.1, 0.0, 1.0));
	return col;
