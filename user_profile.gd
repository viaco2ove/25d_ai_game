# user_profile.gd  用户信息界面
extends Panel



@onready var drafts_btn = $VBoxContainer/DraftsBtn
@onready var logout_btn = $VBoxContainer/LogoutBtn  # 需要在场景中添加此按钮
@onready var close_btn = $VBoxContainer/CloseBtn

var current_user_id: int = -1

func _ready():
	drafts_btn.pressed.connect(_on_drafts_btn_pressed)
	logout_btn.pressed.connect(_on_logout_btn_pressed)
	close_btn.pressed.connect(_on_close_btn_pressed)


# 添加退出按钮处理函数
func _on_logout_btn_pressed():
	# 清除登录状态
	var config = ConfigFile.new()
	config.set_value("login", "user_id", -1)
	config.save("user://settings.cfg")

	# 隐藏当前界面
	visible = false

	# 显示主界面
	var main_scene = get_node("/root/MainNote/MainScene")
	main_scene.current_user_id = -1
	main_scene.visible = true
	main_scene.check_login_status()  # 重新检查登录状态
	
func set_user_id(user_id: int):
	current_user_id = user_id

# 显示草稿箱
func _on_drafts_btn_pressed():
	var draft_list = preload("res://draft_list.tscn").instantiate()
	get_parent().add_child(draft_list)
	draft_list.set_user_id(current_user_id)
	draft_list.draft_selected_edit.connect(_on_draft_selected_edit)

# 草稿被选中
func _on_draft_selected_edit(draft_id: int):
	# 隐藏当前界面
	visible = false

	# 显示故事编辑界面
	var story_creator = get_node("/root/MainNote/StoryCreator")
	story_creator.visible = true
	story_creator.load_draft(draft_id)

# 新增关闭面板函数
func _on_close_btn_pressed():
	# 仅隐藏当前面板，不改变登录状态
	visible = false

	# 显示主界面（根据您的场景结构调整路径）
	var main_scene = get_node("/root/MainNote/MainScene")
	main_scene.visible = true	
