#story_editor.gd -> 故事编辑器场景 for story_editor.tscn(主节点MainNote 内含 MapPreview,$StoryCreator,Database 等子节点)
#story_editor_info.gd-> 故事信息编辑器 for StoryCreator:CanvasLayer  in story_editor.tscn
extends Node2D

var database: Node

# 增加故事的名称,描述,封面 的编辑框
#点击调试后需要保存 地图描述,ai 返回数据， 地图数据,封面。 一个故事有多个地图。增加点击加号就多一个地图描述和调试按钮的功能
#地图的删除,移动位置(顺序)
#最下的保存和发布按钮
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
	database = get_tree().root.get_node("MainNote/Database")
	if database == null:
		push_error("Database node not found! Please check scene structure.")
