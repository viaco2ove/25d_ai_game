# MapPreview.gd (附加到MapPreview节点)
extends SubViewportContainer

@onready var cam: Camera3D = $SubViewport/Camera3D

# 资源缓存
var _material_cache = {}
var _current_map: Node3D
# 修改资源类型声明为 Mesh
var _asset_map = {
	"森林": preload("res://kenney_pirate-kit/Models/OBJ format/grass-patch.obj"),
	"山脉": preload("res://kenney_pirate-kit/Models/OBJ format/rocks-sand-a.obj"),
	"河流": preload("res://kenney_nature-kit/Models/OBJ format/ground_pathBend.obj")
}

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

# 新增地图生成接口
func generate_map(story_text: String):
	set_render_enabled(true)
	_clear_current_map()
	call_deferred("_deferred_generate_map", story_text)

func _clear_current_map():
	for child in $SubViewport.get_children():
		child.queue_free()

func _deferred_generate_map(story_text: String):
	print("开始生成地图场景")
	var keywords = _extract_keywords(story_text)
	var map_node = _create_2_5d_map(keywords)

	# 添加世界环境效果
	var env = WorldEnvironment.new()
	env.environment = _create_environment()
	map_node.add_child(env)

	$SubViewport.add_child(map_node)
	_current_map = map_node

	$SubViewport.size = Vector2(1024, 768)
	$SubViewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	print("地图场景生成完成")

# 地图生成核心函数
func _create_2_5d_map(keywords: Array) -> Node3D:
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
					"mesh": _asset_map[asset_type]  # 这里存储的是 Mesh 资源
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
		multi_instance.material_override = _get_material_by_type(asset_type)
		map_root.add_child(multi_instance)

	# 4. 设置摄像机
	var cam = Camera3D.new()
	cam.position = Vector3(0, 15, 10)
	cam.rotation_degrees = Vector3(-60, 0, 0)
	cam.fov = 75
	cam.current = true
	map_root.add_child(cam)

	# 5. 添加方向光
	var sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-120, 45, 0)
	sun.light_energy = 1.2
	map_root.add_child(sun)

	return map_root

# 工具函数
func _extract_keywords(text: String) -> Array:
	var keywords = []
	var words = text.split(" ")

	for word in words:
		if word.length() > 1:
			var clean_word = word.to_lower().replace(".", "").replace(",", "")
			keywords.append(clean_word)

	return keywords.slice(0, 5)  # 最多5个关键词

func _get_asset_type(keyword: String) -> String:
	var normalized = keyword.to_lower()
	match normalized:
		"森林", "树林", "丛林": return "森林"
		"山脉", "山峰", "山丘": return "山脉"
		"河流", "小溪", "湖泊": return "河流"
		_: return ""

# 修复函数：接受 Mesh 类型而不是 PackedScene
func _create_multimesh(mesh: Mesh, positions: Array) -> MultiMesh:
	var multi = MultiMesh.new()

	# 直接使用传入的 Mesh 资源
	if mesh:
		multi.mesh = mesh
	else:
		push_warning("未找到网格资源，使用默认BoxMesh")
		multi.mesh = BoxMesh.new()

	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.instance_count = positions.size()

	for i in positions.size():
		var transform2 = Transform3D().translated(positions[i])
		multi.set_instance_transform(i, transform2)

	return multi

# 删除不再需要的 _find_mesh_instance 函数
# func _find_mesh_instance(node: Node) -> MeshInstance3D: ...

func _get_material_by_type(type: String) -> StandardMaterial3D:
	if not _material_cache.has(type):
		var mat = StandardMaterial3D.new()
		match type:
			"森林":
				mat.albedo_color = Color(0.1, 0.6, 0.1)
				mat.roughness = 0.8
			"山脉":
				mat.albedo_color = Color(0.5, 0.4, 0.3)
				mat.metallic = 0.4
			"河流":
				mat.albedo_color = Color(0.2, 0.4, 1.0)
				mat.metallic = 0.9
				mat.roughness = 0.1
		_material_cache[type] = mat
	return _material_cache[type]

func _create_environment() -> Environment:
	var env = Environment.new()
	env.glow_enabled = true
	env.glow_intensity = 0.6

	# 新增：环境光遮蔽
	env.ssao_enabled = true
	env.ssao_intensity = 0.5
	env.ssao_radius = 1.0

	# 新增：雾效增强深度感
	env.fog_enabled = true
	env.fog_depth_begin = 15
	env.fog_depth_end = 30
	env.fog_depth_curve = 0.5

	return env

func _create_terrain() -> Node3D:
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(20, 20)
	plane_mesh.subdivide_width = 10
	plane_mesh.subdivide_depth = 10

	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = plane_mesh

	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.3, 0.6, 0.3)
	material.roughness = 0.9
	mesh_instance.material_override = material

	mesh_instance.position = Vector3(0, -1, 0) # 稍微下沉
	return mesh_instance
