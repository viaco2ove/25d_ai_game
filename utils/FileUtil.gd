# res://util/FileUtil.gd
extends Node

# 从指定路径读取JSON文件并返回解析后的数据
static func load_json(path: String):
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return null

	var json = JSON.new()
	if json.parse(file.get_as_text()) != OK:
		return null

	return json.get_data()
