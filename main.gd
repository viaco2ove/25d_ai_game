extends Node2D

var database: Node
# MainNote.gd
func _ready():
	var rootTree = get_tree().root.get_tree_string()
	print("root：" , rootTree)  # 打印根节点下的所有子节点
	
	# 确保节点存在
	var map_preview = $MapPreview
	var story_creator = $StoryCreator
	
	# 传递引用
	story_creator.map_preview = map_preview
	
	# 设置初始状态
	map_preview.visible = true

	# 使用更可靠的节点获取方式
	database = get_tree().root.get_node("MainNote/Database")

	# 如果还是 null，尝试使用延迟获取
	if database == null:
		call_deferred("_deferred_setup_database")


func _deferred_setup_database():
	database = get_tree().root.get_node("data/Database")
	if database == null:
		push_error("Database node not found! Please check scene structure.")
