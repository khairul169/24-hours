extends Reference

var noise;
var fractal;

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

func get_height_at(pos):
	if (typeof(pos) == TYPE_VECTOR2):
		return fractal.get_noise_2dv(pos);
	if (typeof(pos) == TYPE_VECTOR3):
		return fractal.get_noise_2d(pos.x, pos.z);
	return 0.0;

func generate_mesh(position, size, resolution, height, factor):
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
				fractal.get_noise_2dv((world_pos + pos[0]) / factor) * height,
				fractal.get_noise_2dv((world_pos + pos[1]) / factor) * height,
				fractal.get_noise_2dv((world_pos + pos[2]) / factor) * height,
				fractal.get_noise_2dv((world_pos + pos[3]) / factor) * height
			];
			
			for i in ht:
				if (highest == null || i > highest):
					highest = i;
				if (lowest == null || i < lowest):
					lowest = i;
			
			var uv2_size = 20.0;
			
			# triangle 1
			surface.add_uv(Vector2(pos[0].x, pos[0].y));
			surface.add_uv2(Vector2(pos[0].x, pos[0].y) / uv2_size);
			surface.add_vertex(Vector3(pos[0].x, ht[0], pos[0].y));
			
			surface.add_uv(Vector2(pos[1].x, pos[1].y));
			surface.add_uv2(Vector2(pos[1].x, pos[1].y) / uv2_size);
			surface.add_vertex(Vector3(pos[1].x, ht[1], pos[1].y));
			
			surface.add_uv(Vector2(pos[2].x, pos[2].y));
			surface.add_uv2(Vector2(pos[2].x, pos[2].y) / uv2_size);
			surface.add_vertex(Vector3(pos[2].x, ht[2], pos[2].y));
			
			# triangle 2
			surface.add_uv(Vector2(pos[2].x, pos[2].y));
			surface.add_uv2(Vector2(pos[2].x, pos[2].y) / uv2_size);
			surface.add_vertex(Vector3(pos[2].x, ht[2], pos[2].y));
			
			surface.add_uv(Vector2(pos[3].x, pos[3].y));
			surface.add_uv2(Vector2(pos[3].x, pos[3].y) / uv2_size);
			surface.add_vertex(Vector3(pos[3].x, ht[3], pos[3].y));
			
			surface.add_uv(Vector2(pos[0].x, pos[0].y));
			surface.add_uv2(Vector2(pos[0].x, pos[0].y) / uv2_size);
			surface.add_vertex(Vector3(pos[0].x, ht[0], pos[0].y));
	
	surface.index();
	surface.generate_normals();
	var mesh = surface.commit();
	#surface.clear();
	return mesh;
