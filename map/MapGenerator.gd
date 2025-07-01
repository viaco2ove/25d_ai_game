# godot4.4.1
# 动态加载配置文件
class_name MapGenerator
var _terrain_params = _load_json("res://config/TerrainParameters.json")
var _resource_bindings = _load_json("res://config/ResourceBindings.json")
var _material_cache = {}
var _position_reference_points = {}

func generate_from_data(data: Dictionary) -> Node3D:
	var map_root = Node3D.new()

	# 1. 动态创建地形基底
	var ground = _create_terrain(data)
	map_root.add_child(ground)

	# 2. 动态生成物体（通过JSON配置匹配模型）
	_generate_objects(data, map_root)

	# 3. 动态配置光照
	var sun = _create_sun_light(data)
	map_root.add_child(sun)

	# 4. 添加天气效果
	var weather = _create_weather(data)
	if weather:
		map_root.add_child(weather)

	return map_root

func _create_weather(data: Dictionary) -> Node:
	var atmosphere = data.get("atmosphere", {})
	var weather_type = atmosphere.get("weather", "")

	if weather_type.is_empty():
		return null

	# 从资源绑定获取天气配置
	var weather_configs = _resource_bindings.get("weather_settings", {})
	if not weather_configs.has(weather_type):
		push_error("未知天气类型: " + weather_type)
		return null

	var config = weather_configs[weather_type]

	# 创建环境节点
	var env = WorldEnvironment.new()
	var environment = Environment.new()

	# 配置雾效
	if config.get("fog_enabled", false):
		environment.fog_enabled = true
		environment.volumetric_fog_albedo = Color(config.get("fog_color", "#FFFFFF"))
		environment.fog_depth_begin = config.get("fog_start", 5.0)
		environment.fog_depth_end = config.get("fog_end", 50.0)
		environment.fog_depth_curve = config.get("fog_curve", 1.0)

	# 配置粒子效果
	if config.get("particles_enabled", false):
		var particles = GPUParticles3D.new()
		particles.process_material = load(config["particle_material"])
		particles.amount = config.get("particle_amount", 100)
		particles.explosiveness = config.get("particle_density", 0.8)
		particles.lifetime = config.get("particle_lifetime", 2.0)
		particles.position = Vector3(0, config.get("particle_height", 10.0), 0)
		env.add_child(particles)

	env.environment = environment
	return env

func _create_terrain(data: Dictionary) -> MeshInstance3D:
	var plane = PlaneMesh.new()
	plane.size = Vector2(20, 20)
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = plane

	# 从JSON读取基底颜色
	var biome = data["biome"].get("biome_type", "")
	if biome.is_empty() or not _terrain_params["biomes"].has(biome):
		push_error("未知生物群系: " + biome)
		return MeshInstance3D.new()  # 返回空节点避免崩溃

	var biome_dict = _terrain_params.get("biomes", {}).get(biome, {})
	print("biome_dict: ", biome_dict)
	var color_data = biome_dict.get("base_color", [0.3, 0.6, 0.3])  # 默认灰色
	var base_color = Color(color_data[0], color_data[1], color_data[2])

	var material = StandardMaterial3D.new()
	material.albedo_color = base_color
	material.roughness = 0.9
	mesh_instance.material_override = material

	# 调整地形基底高度
	mesh_instance.position = Vector3(0, 0, 0)

	return mesh_instance

func _generate_objects(data: Dictionary, parent: Node3D):
	# 获取元素列表
	var elements = data.get("elements", [])

	for element in elements:
		var element_type = element["mode_type"]
		var element_name = element["mode_name"]
		var position = element["position"]
		var size = element["size"]
		var rotation = element.get("rotation", 0)

		# 根据元素类型和名称获取模型路径
		var model_mapping = ""
		match element_type:
			"elevation":
				model_mapping = _resource_bindings["elevation_mapping"].get(element_name, "")
			"water":
				model_mapping = _resource_bindings["water_mapping"].get(element_name, "")
			"settlements":
				model_mapping = _resource_bindings["settlements_mapping"].get(element_name, "")
			"vegetation":
				model_mapping = _resource_bindings["vegetation_mapping"].get(element_name, "")


		if model_mapping.is_empty() :
			push_error("未找到模型: " + model_mapping)
			continue
		
		var asset_type = ""
		asset_type = _resource_bindings["asset_type"].get(model_mapping, "")
		if asset_type.is_empty():
			push_error("未知资产类型: " + asset_type)
			continue

		var model_path = ""
		model_path = _resource_bindings["model_bindings"].get(asset_type, "")

		if model_path.is_empty() or not ResourceLoader.exists(model_path):
			push_error("未找到模型: " + element_name + " 路径: " + model_path)
			continue

		var asset = load(model_path)
		var instance = MeshInstance3D.new()
		instance.mesh = asset

		# 设置位置（注意：y轴高度根据类型调整）
		var y_pos = 0.0
		if element_type == "elevation":
			y_pos = 0  # 抬高地形?
		instance.position = Vector3(position["x"], y_pos, position["z"])

		# 设置旋转
		instance.rotation_degrees.y = rotation

		# 设置缩放（根据尺寸）
		instance.scale = Vector3(size["width"], 1.0, size["depth"])

		# 设置材质
		if element_type == "vegetation" and data.get("biome", {}).has("base_color"):
			var color_hex = data["biome"]["base_color"]
			instance.material_override = _get_material_with_color(element_type, color_hex)
		else:
			instance.material_override = _get_material_by_type(element_name)

		parent.add_child(instance)

# 获取带特定颜色的材质
func _get_material_with_color(type: String, color_hex: String) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(color_hex)

	match type:
		"森林":
			mat.roughness = 0.8
		"山脉":
			mat.metallic = 0.4
		"河流":
			mat.metallic = 0.9
			mat.roughness = 0.1

	return mat

func _get_material_by_type(type: String) -> StandardMaterial3D:
	if not _material_cache.has(type):
		var mat = StandardMaterial3D.new()
		var config = _resource_bindings["material_cache"].get(type, {})

		if config.is_empty():
			match type:
				"魔法森林":
					mat.albedo_color = Color(0.2, 0.4, 0.1)
				_:
					mat.albedo_color = Color(0.5, 0.5, 0.5)
		else:
			var albedo_data = config.get("albedo_color", [0.5, 0.5, 0.5])
			var albedo_color: Color
			if albedo_data is Array and albedo_data.size() >= 3:
				albedo_color = Color(albedo_data[0], albedo_data[1], albedo_data[2])
				if albedo_data.size() >= 4:
					albedo_color.a = albedo_data[3]
			else:
				push_error("无效的颜色配置: " + str(albedo_data))
				albedo_color = Color(0.5, 0.5, 0.5)

			mat.albedo_color = albedo_color
			mat.roughness = config.get("roughness", 0.9)
		_material_cache[type] = mat
	return _material_cache[type]

func _create_sun_light(data: Dictionary) -> DirectionalLight3D:
	var atmosphere = data.get("atmosphere", {})
	var light_type = atmosphere.get("light", "白天")
	var light_dict = _resource_bindings.get("light_settings", {})

	if light_dict.has(light_type):
		var settings = light_dict[light_type]
		var sun = DirectionalLight3D.new()
		sun.light_energy = settings["energy"]
		sun.light_color = Color(settings["color"][0], settings["color"][1], settings["color"][2])
		sun.rotation_degrees = Vector3(settings["rotation"][0], settings["rotation"][1], settings["rotation"][2])
		return sun
	else:
		push_error("未知光照类型: " + light_type)
		return DirectionalLight3D.new()

# 支持带注释的 JSON 加载器
func _load_json(path: String) -> Dictionary:
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("配置文件不存在: " + path)
		return {}

	var json_text = file.get_as_text()
	var json = JSON.new()
	var error = json.parse(json_text)

	if error != OK:
		var error_line = json.get_error_line()
		var error_msg = json.get_error_message()
		push_error("JSON解析失败！路径: %s, 行: %d, 错误: %s" % [path, error_line, error_msg])
		return {}

	return json.data
