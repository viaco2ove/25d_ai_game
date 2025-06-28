# res://config/MapConfig.gd
extends Node
# 添加对FileUtil的引用
const FileUtil = preload("res://utils/FileUtil.gd")

# 地图基础配置（默认值）
var config = {
				 "size": Vector2(20, 20),  # 地图尺寸 (x,z)
				 "origin": Vector2(0, 0),  # 坐标原点
				 "x_range": Vector2(-10, 10),  # x轴范围
				 "z_range": Vector2(-10, 10),  # z轴范围
				 "height_range": Vector2(-1, 5)  # 高度范围
			 }

# 从JSON文件加载配置
func load_from_json(path: String) -> bool:
	# 使用FileUtil读取JSON数据
	var data = FileUtil.load_json(path)
	if not data is Dictionary:
		return false

	# 转换并合并配置
	return _convert_and_merge_config(data)

# 转换并合并配置数据
func _convert_and_merge_config(data: Dictionary) -> bool:
	# 需要转换为Vector2的字段列表
	var vector_fields = ["size", "origin", "x_range", "z_range", "height_range"]

	for key in data:
		if config.has(key):
			var value = data[key]

			# 处理Vector2转换
			if key in vector_fields:
				if value is Array and value.size() == 2:
					config[key] = Vector2(value[0], value[1])
				elif value is Vector2:
					config[key] = value
				else:
					push_error("无效的Vector2数据: " + key)
					return false
			else:
				# 其他字段直接赋值
				config[key] = value
		else:
			push_warning("未知配置项: " + key)

	return true

# 获取地图尺寸
func get_size() -> Vector2:
	return config.get("size", Vector2(20, 20))

# 获取坐标范围
func get_range(axis: String) -> Vector2:
	match axis:
		"x": return config.get("x_range", Vector2(-10, 10))
		"z": return config.get("z_range", Vector2(-10, 10))
		"height": return config.get("height_range", Vector2(-1, 5))
	return Vector2.ZERO
