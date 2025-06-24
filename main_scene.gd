extends CanvasLayer

@onready var add_btn: Button = $BottomMenu/AddBtn


func _ready():
	add_btn.pressed.connect(_on_AddBtn_pressed)
	var story_creator = get_node("/root/MainNote/StoryCreator")
	story_creator.visible = false
	
func _on_AddBtn_pressed():
	print("尝试加载场景:StoryCreator")
	
	# 隐藏当前界面
	visible = false
	
	# 显示目标界面（无动画）
	var story_creator = get_node("/root/MainNote/StoryCreator")
	story_creator.visible = true
	
