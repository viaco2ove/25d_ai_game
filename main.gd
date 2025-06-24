extends Node2D

# MainNote.gd
func _ready():
	# 确保节点存在
	var map_preview = $MapPreview
	var story_creator = $StoryCreator
	
	# 传递引用
	story_creator.map_preview = map_preview
	
	# 设置初始状态
	map_preview.visible = true
