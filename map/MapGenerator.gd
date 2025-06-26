# godot4.4.1
# 动态加载配置文件
class_name MapGenerator
var _terrain_params = _load_json("res://config/TerrainParameters.json")
var _resource_bindings = _load_json("res://config/ResourceBindings.json")
var _material_cache = {}
var _position_reference_points = {}

func generate_from_data(data: Dictionary) -> Node3D:
	var map_root = Node3D.new()
	# 0. 处理位置参考点
	_process_position_data(data)
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
	
	# 配置雾效（示例）
	if config.get("fog_enabled", false):
		environment.fog_enabled = true
		environment.volumetric_fog_albedo = Color(config.get("fog_color", "#FFFFFF"))
		environment.fog_depth_begin = config.get("fog_start", 5.0)
		environment.fog_depth_end = config.get("fog_end", 50.0)
		environment.fog_depth_curve = config.get("fog_curve", 1.0)
	
	# 配置粒子效果（示例）
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
	
# 处理位置数据并缓存参考点
func _process_position_data(data: Dictionary):
	var position = data.get("position", {})
	if not position.is_empty():
		var ref_point = position.get("reference_point", "")
		var distance = position.get("distance", 0.5)
		
		# 生成参考点位置（随机但符合距离约束）
		var ref_pos = Vector3(
			randf_range(-10 * distance, 10 * distance),
			0,
			randf_range(-10 * distance, 10 * distance)
		)
		
		_position_reference_points[ref_point] = ref_pos

func _create_terrain(data: Dictionary) -> MeshInstance3D:
	var plane = PlaneMesh.new()
	plane.size = Vector2(20, 20)
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = plane

	# 从JSON读取基底颜色
	var biome = data["biome"]
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
	
	# 根据地形起伏调整高度
	var elevation_intensity = data.get("elevation", {}).get("intensity", 0.0)
	mesh_instance.position = Vector3(0, -1 - elevation_intensity * 3, 0)

	return mesh_instance

func _generate_objects(data: Dictionary, parent: Node3D):
	var keywords = _convert_data_to_keywords(data)
	var multimeshes = {}
	
	# 获取地形高度
	var elevation_intensity = data.get("elevation", {}).get("intensity", 0.0)
	var ground_height = -1 - elevation_intensity * 3
	
	# 1. 处理位置约束
	var position_constraint = data.get("position", {})
	var settlements = data.get("settlements", {})
	var settlement_constraint = settlements.get("position", {})
	
	for keyword in keywords:
		# 从JSON获取模型路径
		var asset_type = _resource_bindings["asset_type"].get(keyword, "")
		var model_path = _resource_bindings["model_bindings"].get(asset_type, "")
		
		
		if model_path && ResourceLoader.exists(model_path):
			var asset = load(model_path)
			
			if not multimeshes.has(asset_type):
				multimeshes[asset_type] = {
					"positions": [],
					"mesh": asset
				}
			
			# 2. 确定物体密度
			var density = 1.0
			if asset_type == "森林":
				density = data.get("vegetation", {}).get("density", 1.0)
			elif asset_type == "村庄":  # 村庄、哨站等
				density = settlements.get("density", 0.3)
			
			var count = max(1, int(5 * density))
			
			# 3. 根据位置约束生成位置
			for i in count:
				var position = Vector3.ZERO
				
				# 3.1 处理位置约束
				if not position_constraint.is_empty() and keyword == position_constraint.get("reference_point", ""):
					var ref_point = position_constraint["reference_point"]
					var distance = position_constraint.get("distance", 0.5)
					
					if _position_reference_points.has(ref_point):
						var ref_pos = _position_reference_points[ref_point]
						position = ref_pos + Vector3(
							randf_range(-5 * distance, 5 * distance),
							 ground_height,  # 使用地形高度
							randf_range(-5 * distance, 5 * distance)
						)
				
				# 3.2 处理定居点位置约束
				elif not settlement_constraint.is_empty() and keyword == settlement_constraint.get("reference_point", ""):
					var ref_point = settlement_constraint["reference_point"]
					var distance = settlement_constraint.get("distance", 0.3)
					
					if _position_reference_points.has(ref_point):
						var ref_pos = _position_reference_points[ref_point]
						position = ref_pos + Vector3(
							randf_range(-3 * distance, 3 * distance),
							 ground_height,  # 使用地形高度
							randf_range(-3 * distance, 3 * distance)
						)
				
				# 3.3 无位置约束的随机分布
				else:
					position = Vector3(
						randf_range(-8, 8),
						 ground_height,  # 使用地形高度
						randf_range(-8, 8)
					)
				
				multimeshes[asset_type]["positions"].append(position)
	
	# 4. 批量渲染物体
	for asset_type in multimeshes:
		var mesh_data = multimeshes[asset_type]
		
		# 4.1 创建多网格实例
		var multi_instance = MultiMeshInstance3D.new()
		multi_instance.multimesh = _create_multimesh(mesh_data["mesh"], mesh_data["positions"])
		
		# 4.2 处理特殊材质
		if asset_type == "森林" and data.has("vegetation") and data["vegetation"].has("color"):
			var color_hex = data["vegetation"]["color"]
			multi_instance.material_override = _get_material_with_color(asset_type, color_hex)
		else:
			multi_instance.material_override = _get_material_by_type(asset_type)
		
		var settlements_type = _resource_bindings["settlements_mapping"].get(asset_type, "")
		print("settlements_type: ", settlements_type)
		# 4.3 处理定居点高度
		if settlements_type != "":
			# 如果是山下村庄，降低高度
			if settlement_constraint.get("distance", 1.0) < 0.3:
				multi_instance.position.y = -1.0
		
		parent.add_child(multi_instance)
		
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
		
# 创建多网格实例
func _create_multimesh(mesh: Mesh, positions: Array) -> MultiMesh:
	var multi = MultiMesh.new()
	multi.mesh = mesh if mesh else BoxMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.instance_count = positions.size()

	for i in positions.size():
		multi.set_instance_transform(i, Transform3D().translated(positions[i]))

	return multi

func _get_material_by_type(type: String) -> StandardMaterial3D:
	if not _material_cache.has(type):
		var mat = StandardMaterial3D.new()
		var config = _resource_bindings["material_cache"].get(type, {})

		if config.is_empty():
			match type:				 # 4 空格
				"魔法森林":			 # 4 空格（与上一行对齐）
					mat.albedo_color = Color(0.2, 0.4, 0.1)  # 8 空格（二级缩进）
				_:
					mat.albedo_color = Color(0.5, 0.5, 0.5)
		else:
			var albedo_data = config.get("albedo_color", [0.5, 0.5, 0.5])
			var albedo_color: Color
			if albedo_data is Array and albedo_data.size() >= 3:
				# 显式传递分量参数
				albedo_color = Color(albedo_data[0], albedo_data[1], albedo_data[2])
				if albedo_data.size() >= 4:  # 处理Alpha通道
					albedo_color.a = albedo_data[3]
			else:
				push_error("无效的颜色配置: " + str(albedo_data))
				albedo_color = Color(0.5, 0.5, 0.5)  # 默认灰色
			
			mat.albedo_color = albedo_color
			
		mat.roughness = config.get("roughness", 0.9)
		_material_cache[type] = mat
	return _material_cache[type]

func _create_sun_light(data: Dictionary) -> DirectionalLight3D:
	var light_type = data["atmosphere"]["light"]
	var light_dict = _resource_bindings.get("light_settings", {})
	
	if light_dict.has(light_type):
		var settings = light_dict[light_type]
		# 创建光照逻辑
		var sun = DirectionalLight3D.new()
		sun.light_energy = settings["energy"]
		sun.light_color = Color(settings["color"][0], settings["color"][1], settings["color"][2])
		sun.rotation_degrees = Vector3(settings["rotation"][0], settings["rotation"][1], settings["rotation"][2])
		return sun
	else:
		push_error("未知光照类型: " + light_type)
		# 返回默认光照或空对象
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
	
# 清理非法字符和BOM头
func _clean_json_text(text: String) -> String:
	# 移除BOM头（EF BB BF）
	if text.begins_with("\ufeff"):
		text = text.substr(1)
	# 移除零宽空格（U+200B）
	text = text.replace("\u200B", "")
	# 删除所有注释（正则匹配）
	var regex = RegEx.new()
	regex.compile("//.*|/\\*[\\s\\S]*?\\*/")
	return regex.sub(text, "", true)

# 注释剥离核心逻辑
func _strip_json_comments(json_text: String) -> String:
	var lines = json_text.split("\n")
	var clean_lines = []
	var in_block_comment = false

	for line in lines:
		var clean_line = ""
		var i = 0
		while i < line.length():
			# 处理块注释结束
			if in_block_comment:
				if i + 1 < line.length() and line[i] == "*" and line[i + 1] == "/":
					in_block_comment = false
					i += 2  # 跳过 "*/"
					continue
				i += 1
				continue

			# 检测块注释开始
			if i + 1 < line.length() and line[i] == "/" and line[i + 1] == "*":
				in_block_comment = true
				i += 2
				continue

			# 检测单行注释
			if i + 1 < line.length() and line[i] == "/" and line[i + 1] == "/":
				break  # 忽略行剩余部分

			clean_line += line[i]
			i += 1

		# 添加非空行且不在块注释中
		if not in_block_comment and clean_line.strip_edges() != "":
			clean_lines.append(clean_line)

	return "\n".join(clean_lines)

# 将地形数据转换为关键词
func _convert_data_to_keywords(data: Dictionary) -> Array:
	var keywords = []
	var biome = data.get("biome", "")

	# 1. 从JSON获取关键词映射规则
	var biome_rules = _terrain_params["biomes"].get(biome, {})
	if biome_rules.is_empty():
		return keywords

	# 2. 添加生物群系关键词（小写标准化）
	keywords.append(biome.to_lower())

	# 3. 动态生成地形特征关键词
	var elevation = data.get("elevation", {})
	if elevation.get("intensity", 0.0) > 0.1:
		var elevation_type = elevation.get("type", "")
		# 从配置映射中获取资源类型（如"火山"→"山脉"）
		var asset_type = ""
		if _resource_bindings.has("elevation_mapping"):
			var elevation_map = _resource_bindings["elevation_mapping"]
			asset_type = elevation_map.get(elevation_type, "")
		else:
			push_error("键 'elevation_mapping' 缺失！")
		if not asset_type.is_empty():
			keywords.append(asset_type.to_lower())

	# 4. 动态生成水域关键词
	var water = data.get("water", {})
	if water.get("coverage", 0.0) > 0:
		var water_type = water.get("type", "")
		var water_asset = ""
		if _resource_bindings.has("water_mapping"):
			var water_map = _resource_bindings["water_mapping"]
			water_asset = water_map.get(water_type, "")
		else:
			push_error("关键配置缺失: water_mapping")
		if not water_asset.is_empty():
			keywords.append(water_asset.to_lower())
			
	# 5. 建筑
	var settlements = data.get("settlements", {})
	if settlements.get("density", 0.0) > 0:
		var settlements_type = settlements.get("type", "")
		var settlements_asset = ""
		if _resource_bindings.has("settlements_mapping"):
			var settlements_map = _resource_bindings["settlements_mapping"]
			settlements_asset = settlements_map.get(settlements_type, "")
		else:
			push_error("关键配置缺失: settlements_mapping")
		if not settlements_asset.is_empty():
			keywords.append(settlements_asset.to_lower())		
	return keywords
	
