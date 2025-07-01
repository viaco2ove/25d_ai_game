extends CanvasLayer
# godot4.4.1

@onready var add_btn: Button = $BottomMenu/MenuContainer/AddBtn
@onready var user_btn: Button = $BottomMenu/MenuContainer/UserBtn
var database: Node
var current_user_id: int = -1  # -1表示未登录

# 在文件顶部添加工具类引用
const ToastUtils = preload("res://utils/toast_utils.gd")

func _ready():
	# 获取数据库节点
	database = get_tree().root.get_node("MainNote/Database")

	# 检查登录状态
	check_login_status()

	# 连接按钮信号
	add_btn.pressed.connect(_on_AddBtn_pressed)
	user_btn.pressed.connect(_on_UserBtn_pressed)

	var story_creator = get_node("/root/MainNote/StoryCreator")
	story_creator.visible = false

	for button in $BottomMenu/MenuContainer.get_children():
		button.pressed.connect(_on_button_pressed.bind(button))
		
	check_auto_login()	

func check_auto_login():
	# 使用 ConfigManager 加载配置
	var config_manager = ConfigManager.new()
	var config = config_manager.load_config()

	# 从配置中获取用户ID
	current_user_id = config.get_value("login", "user_id", -1)
	if current_user_id != -1:
		ToastUtils.show_toast("自动登录成功！用户ID: %d" % current_user_id, 2.0, self)
		# 隐藏登录界面（如果存在）
		if has_node("LoginUI"):
			get_node("LoginUI").queue_free()

				
# 检查登录状态
func check_login_status():
	# TODO: 从本地存储加载登录状态（如ConfigFile）
	if current_user_id == -1:
		show_login_ui()

# 显示登录界面
func show_login_ui():
	# 创建登录界面实例
	var login_ui = preload("res://login_ui.tscn").instantiate()
	add_child(login_ui)

	# 连接登录界面信号
	login_ui.login_success.connect(_on_login_success)
	login_ui.register_request.connect(_on_register_request)

# 登录成功回调
func _on_login_success(user_id: int):
	print("_on_login_success")
	current_user_id = user_id

	# 使用 ConfigManager 保存登录状态
	var config_manager = ConfigManager.new()
	var config = config_manager.load_config()
	config.set_value("login", "user_id", user_id)
	config_manager.save_config(config)  # 使用 save_config 方法保存

	# 显示登录成功提示
	ToastUtils.show_toast("登录成功！用户ID: %d" % user_id, 2.0, self)

	# 隐藏登录界面
	var login_ui = get_node("LoginUI")
	if login_ui:
		login_ui.queue_free()


# 注册请求回调
func _on_register_request():
	# 创建注册界面实例
	var register_ui = preload("res://register_ui.tscn").instantiate()
	add_child(register_ui)

	# 连接注册界面信号
	register_ui.register_success.connect(_on_register_success)

# 注册成功回调
func _on_register_success(user_id: int):
	current_user_id = user_id
	# TODO: 保存登录状态到本地存储

	# 隐藏注册界面
	var register_ui = get_node("RegisterUI")
	if register_ui:
		register_ui.queue_free()

func _on_AddBtn_pressed():
	if current_user_id == -1:
		show_login_ui()
		return

	print("尝试加载场景:StoryCreator")
	var draft_id = database.create_draft(current_user_id)
	visible = false
	var story_creator = get_node("/root/MainNote/StoryCreator")
	story_creator.visible = true

func _on_UserBtn_pressed():
	if current_user_id == -1:
		show_login_ui()
	else:
		# 显示用户信息界面
		show_user_profile()

func show_user_profile():
	# 创建用户信息界面实例
	var profile_ui = preload("res://user_profile.tscn").instantiate()
	add_child(profile_ui)

	# 传递用户ID
	profile_ui.set_user_id(current_user_id)

func _on_button_pressed(button: Button):
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2(0.95, 0.95), 0.05)
	tween.tween_property(button, "scale", Vector2(1, 1), 0.05)
