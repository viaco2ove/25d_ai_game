extends CanvasLayer
# godot4.4.1

@onready var add_btn: Button = $BottomMenu/MenuContainer/AddBtn


func _ready():
	add_btn.pressed.connect(_on_AddBtn_pressed)
	var story_creator = get_node("/root/MainNote/StoryCreator")
	story_creator.visible = false
	
	for button in $BottomMenu/MenuContainer.get_children():
		button.pressed.connect(_on_button_pressed.bind(button))
	
func _on_AddBtn_pressed():
	print("尝试加载场景:StoryCreator")
	
	# 隐藏当前界面
	visible = false
	
	# 显示目标界面（无动画）
	var story_creator = get_node("/root/MainNote/StoryCreator")
	story_creator.visible = true


func _on_button_pressed(button: Button):
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2(0.95, 0.95), 0.05)
	tween.tween_property(button, "scale", Vector2(1, 1), 0.05)
