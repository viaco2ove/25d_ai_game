# res://config/MapConfig.gd
extends Node

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
	var file = FileAccess.open(path, FileAccess.READ)
	if not file: 
		return false

	var json = JSON.new()
	if json.parse(file.get_as_text()) != OK: 
		return false

	var data = json.get_data()
	if data is Dictionary:
		# 转换关键字段为Vector2
		config = _convert_json_data(data)
		return true
	return false

# 辅助函数：转换JSON数据中的数组为Vector2
func _convert_json_data(raw_data: Dictionary) -> Dictionary:
	var converted = {}
	
	# 转换所有Vector2类型的字段
	for key in ["size", "origin", "x_range", "z_range", "height_range"]:
		if key in raw_data:
			var value = raw_data[key]
			if value is Array and value.size() >= 2:
				converted[key] = Vector2(value[0], value[1])
			elif value is Dictionary and "x" in value and "y" in value:
				converted[key] = Vector2(value["x"], value["y"])
			else:
				converted[key] = value
		else:
			# 保留未转换的字段
			converted[key] = raw_data.get(key, config.get(key))
	
	# 保留其他可能存在的字段
	for key in raw_data:
		if not key in converted:
			converted[key] = raw_data[key]
	
	return converted

# 获取地图尺寸
func get_size() -> Vector2:
	var raw_size = config.get("size", Vector2(20, 20))  # 默认使用数组格式
	
	# 类型转换处理
	if raw_size is Vector2:
		return raw_size
	elif raw_size is Array and raw_size.size() >= 2:
		return Vector2(raw_size[0], raw_size[1])
	else:
		push_error("Invalid size format in config, using default")
		return Vector2(20, 20)
# 获取坐标范围
func get_range(axis: String) -> Vector2:
	match axis:
		"x": return config.get("x_range", Vector2(-10, 10))
		"z": return config.get("z_range", Vector2(-10, 10))
		"height": return config.get("height_range", Vector2(-1, 5))
	return Vector2.ZERO
