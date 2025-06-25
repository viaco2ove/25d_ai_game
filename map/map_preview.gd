# map_preview.gd (附加到MapPreview节点)
extends SubViewportContainer

@onready var cam: Camera3D = $SubViewport/Camera3D

# 地图生成器
var map_generator = load("res://map/MapGenerator.gd").new()

# 当前地图节点
var _current_map: Node3D

func _ready():
	# 设置初始尺寸
	size = Vector2(800, 600)

	# 设置子视口
	$SubViewport.size = size

	# 监听尺寸变化
	resized.connect(_on_resized)

	cam.position = Vector3(0, 20, 15)	# 提高Y轴位置，增强2.5D效果
	cam.rotation_degrees = Vector3(-70, 0, 0)	# 调整角度，更接近2.5D视角
	cam.fov = 65	# 减小视野角度，减少透视畸变
	cam.current = true

func _on_resized():
	$SubViewport.size = size

func set_render_enabled(enabled: bool):
	# 控制渲染开销
	$SubViewport.render_target_update_mode = (
	SubViewport.UPDATE_ALWAYS if enabled
	else SubViewport.UPDATE_DISABLED
	)

# 清除当前地图
func _clear_current_map():
	# 递归删除所有非Camera节点
	for child in $SubViewport.get_children():
		if child != cam:  # 保留相机
			_recursive_delete(child)

func _recursive_delete(node: Node):
	for child in node.get_children():
		_recursive_delete(child)  # 递归删除所有子节点
	node.queue_free()

func reset_viewport():
	# 1. 停止渲染更新
	set_render_enabled(false)

	# 2. 清除场景节点（递归删除）
	_clear_current_map()

	# 3. 强制渲染一帧空白画面
	$SubViewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	await get_tree().create_timer(0.1).timeout  # 更可靠的延迟等待

	# 4. 释放GPU资源
	_clear_gpu_resources()

	# 5. 重置相机位置（可选）
	cam.position = Vector3(0, 20, 15)
	cam.rotation_degrees = Vector3(-70, 0, 0)
	
	print("SubViewport子节点数: ", $SubViewport.get_child_count())
	
func _clear_gpu_resources():
	# 释放MultiMesh等显存占用
	RenderingServer.global_shader_parameter_remove("multimesh_data")
	RenderingServer.force_draw()  # 强制GPU刷新
	
# 根据故事文本生成地图
func generate_map(story_text: String):
	set_render_enabled(true)
	_clear_current_map()
	call_deferred("_deferred_generate_map", story_text)

func _deferred_generate_map(story_text: String):
	print("开始生成地图场景")

	# 提取关键词
	var keywords = _extract_keywords(story_text)

	# 创建地图节点
	var map_node = _create_simple_map(keywords)

	# 添加世界环境效果
	var env = WorldEnvironment.new()
	env.environment = _create_default_environment()
	map_node.add_child(env)

	$SubViewport.add_child(map_node)
	_current_map = map_node

	$SubViewport.size = Vector2(1024, 768)
	$SubViewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	print("地图场景生成完成")

# 简单地图生成函数（基于关键词）
func _create_simple_map(keywords: Array) -> Node3D:
	var map_root = Node3D.new()

	# 1. 生成地形基底
	var ground = _create_terrain()
	map_root.add_child(ground)

	# 2. 关键词物体生成
	var multimeshes = {}
	for keyword in keywords:
		var asset_type = _get_asset_type(keyword)
		if asset_type:
			# 初始化MultiMesh分组
			if not multimeshes.has(asset_type):
				multimeshes[asset_type] = {
					"positions": [],
					"mesh": map_generator._asset_map[asset_type]  # 使用地图生成器的资源
				}
			multimeshes[asset_type]["positions"].append(Vector3(
				randf_range(-8, 8),
				0,
				randf_range(-8, 8)
			))

	# 3. 批量渲染物体
	for asset_type in multimeshes:
		var data = multimeshes[asset_type]
		var multi_instance = MultiMeshInstance3D.new()
		# 直接传递 Mesh 资源而不是 PackedScene
		multi_instance.multimesh = _create_multimesh(data["mesh"], data["positions"])
		multi_instance.material_override = map_generator._get_material_by_type(asset_type)  # 使用生成器的材质
		map_root.add_child(multi_instance)

	# 4. 设置摄像机
	cam.position = Vector3(0, 15, 10)
	cam.rotation_degrees = Vector3(-60, 0, 0)
	cam.fov = 75
	cam.current = true

	# 5. 添加方向光
	var sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-120, 45, 0)
	sun.light_energy = 1.2
	map_root.add_child(sun)

	return map_root

# 根据地形数据生成地图
func generate_from_data(data: Dictionary):
	set_render_enabled(true)
	_clear_current_map()
	call_deferred("_deferred_generate_from_data", data)

func _deferred_generate_from_data(data: Dictionary):
	print("开始基于地形数据生成地图")

	# 使用地图生成器创建地图节点
	var map_node = map_generator.generate_from_data(data)
	map_node.position = Vector3.ZERO

	# 添加世界环境效果（根据地形数据调整环境）
	var env = WorldEnvironment.new()
	env.environment = _create_environment(data)
	map_node.add_child(env)

	$SubViewport.add_child(map_node)
	_current_map = map_node

	$SubViewport.size = Vector2(1024, 768)
	$SubViewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	print("基于AI数据的地图场景生成完成")

# 工具函数：提取关键词
func _extract_keywords(text: String) -> Array:
	var keywords = []
	var words = text.split(" ")

	for word in words:
		if word.length() > 1:
			var clean_word = word.to_lower().replace(".", "").replace(",", "")
			keywords.append(clean_word)

	return keywords.slice(0, 5)  # 最多5个关键词

# 根据关键词获取资源类型
func _get_asset_type(keyword: String) -> String:
	var normalized = keyword.to_lower()
	match normalized:
		"森林", "树林", "丛林": return "森林"
		"山脉", "山峰", "山丘": return "山脉"
		"河流", "小溪", "湖泊": return "河流"
		_: return ""

# 创建多网格实例
func _create_multimesh(mesh: Mesh, positions: Array) -> MultiMesh:
	var multi = MultiMesh.new()
	multi.mesh = mesh if mesh else BoxMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.instance_count = positions.size()

	for i in positions.size():
		multi.set_instance_transform(i, Transform3D().translated(positions[i]))

	return multi

# 创建默认地形基底
func _create_terrain() -> Node3D:
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(20, 20)
	plane_mesh.subdivide_width = 10
	plane_mesh.subdivide_depth = 10

	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = plane_mesh

	var material2 = StandardMaterial3D.new()
	material2.albedo_color = Color(0.3, 0.6, 0.3)
	material2.roughness = 0.9
	mesh_instance.material_override = material2

	mesh_instance.position = Vector3(0, -1, 0) # 稍微下沉
	return mesh_instance

# 创建默认环境（不依赖地形数据）
func _create_default_environment() -> Environment:
	var env = Environment.new()
	env.glow_enabled = true
	env.glow_intensity = 0.6

	# 直接设置 Environment 的雾效参数
	env.fog_enabled = true
	env.fog_depth_begin = 15
	env.fog_depth_end = 30
#	env.volumetric_fog_albedo = Color(0.7, 0.7, 0.75)

	env.ambient_light_color = Color(0.5, 0.5, 0.6)  # 设置雾的反光颜色（Albedo）
	env.ambient_light_energy = 0.5
	return env

func _add_local_fog(map_node: Node3D):
	var fog_volume = FogVolume.new()
	fog_volume.size = Vector3(5, 3, 5)
	fog_volume.position = Vector3(0, 1, 0)
	var fog_material = FogMaterial.new()
	fog_material.density = 0.2
	fog_material.albedo = Color(0.8, 0.8, 0.9)  # 局部雾颜色
	fog_volume.material = fog_material
	map_node.add_child(fog_volume)	

# 根据地形数据创建环境（高级）
func _create_environment(data: Dictionary) -> Environment:
	var env = Environment.new()
	env.glow_enabled = true
	env.glow_intensity = 0.6

	# 根据天气动态配置雾效
	var weather = data.get("atmosphere", {}).get("weather", "晴朗")
	match weather:
		"雾":
			env.fog_enabled = true
			env.fog_depth_begin = 10
			env.fog_depth_end = 20
			#Godot 4 移除了 fog_albedo_color，雾效颜色需通过 ​**fog_light_color**​ 设置			
			env.fog_light_color  = Color(0.8, 0.8, 0.85)
			#对 GPU 开销较大，移动端建议关闭
			env.volumetric_fog_enabled = true
			env.volumetric_fog_density = 0.01  # 雾浓度
			 # 设置雾的反光颜色（Albedo）
			env.volumetric_fog_albedo = Color(0.58431375, 0.16862746, 0.29803923)
		"雨", "雪":
			env.fog_enabled = true
			env.fog_depth_begin = 15
			env.fog_depth_end = 30
			env.fog_light_color  = Color(0.7, 0.7, 0.75)
		_:
			env.fog_enabled = false
	# 根据光照条件调整环境光
	var light = data.get("atmosphere", {}).get("light", "白天")
	match light:
		"黄昏":
			env.ambient_light_color = Color(1.0, 0.7, 0.5)
			env.ambient_light_energy = 0.6
		"夜晚":
			env.ambient_light_color = Color(0.3, 0.4, 0.8)
			env.ambient_light_energy = 0.3
		_:
			env.ambient_light_color = Color(0.5, 0.5, 0.6)
			env.ambient_light_energy = 0.5

	return env
