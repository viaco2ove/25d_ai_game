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
	if not file: return false

	var json = JSON.new()
	if json.parse(file.get_as_text()) != OK: return false

	var data = json.get_data()
	if data is Dictionary:
		config = data
		return true
	return false

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
