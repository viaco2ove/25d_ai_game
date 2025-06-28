extends Panel

@onready var drafts_btn = $VBoxContainer/DraftsBtn
var current_user_id: int = -1

func _ready():
	drafts_btn.pressed.connect(_on_drafts_btn_pressed)

func set_user_id(user_id: int):
	current_user_id = user_id

# 显示草稿箱
func _on_drafts_btn_pressed():
	var draft_list = preload("res://draft_list.tscn").instantiate()
	get_parent().add_child(draft_list)
	draft_list.set_user_id(current_user_id)
	draft_list.draft_selected.connect(_on_draft_selected)

# 草稿被选中
func _on_draft_selected(draft_id: int):
	# 隐藏当前界面
	visible = false

	# 显示故事编辑界面
	var story_creator = get_node("/root/MainNote/StoryCreator")
	story_creator.visible = true
	story_creator.load_draft(draft_id)
