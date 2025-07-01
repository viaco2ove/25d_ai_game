extends Panel

signal register_success(user_id: int)

@onready var username_input: LineEdit = $VBoxContainer/UsernameInput
@onready var nickname_input: LineEdit = $VBoxContainer/NicknameInput
@onready var password_input: LineEdit = $VBoxContainer/PasswordInput
@onready var confirm_password_input: LineEdit = $VBoxContainer/ConfirmPasswordInput
@onready var gender_option: OptionButton = $VBoxContainer/GenderOption
@onready var error_label: Label = $VBoxContainer/ErrorLabel
@onready var register_btn: Button = $VBoxContainer/RegisterBtn
@onready var back_btn: Button = $VBoxContainer/BackBtn

var database: Node

func _ready():
	# 使用更可靠的节点获取方式
	database = get_tree().root.get_node("data/Database")

	# 如果还是 null，尝试使用延迟获取
	if database == null:
		call_deferred("_deferred_setup_database")

	register_btn.pressed.connect(_on_register_btn_pressed)
	back_btn.pressed.connect(_on_back_btn_pressed)


# 隐藏其他界面
	var login_ui = get_node_or_null("/root/LoginUI")
	if login_ui:
		login_ui.visible = false

	var main_ui = get_node_or_null("/root/MainUI")
	if main_ui:
		main_ui.visible = false

	# 回车键提交
	username_input.text_submitted.connect(_on_text_submitted)
	nickname_input.text_submitted.connect(_on_text_submitted)
	password_input.text_submitted.connect(_on_text_submitted)
	confirm_password_input.text_submitted.connect(_on_text_submitted)

func _deferred_setup_database():
	database = get_tree().root.get_node("data/Database")
	if database == null:
		push_error("Database node not found! Please check scene structure.")
		
func _on_back_btn_pressed():
	# 显示登录界面
	var login_ui = get_node_or_null("/root/LoginUI")
	if login_ui:
		login_ui.visible = true

	# 隐藏注册界面
	self.visible = false
	
func _on_text_submitted(_text: String):
	_on_register_btn_pressed()

func _on_register_btn_pressed():
	var username = username_input.text.strip_edges()
	var nickname = nickname_input.text.strip_edges()
	var password = password_input.text.strip_edges()
	var confirm_password = confirm_password_input.text.strip_edges()
	var gender = gender_option.get_item_text(gender_option.selected)

	# 输入验证
	if username.length() < 3 or username.length() > 20:
		error_label.text = "昵称长度需在3-20字符之间"
		username_input.grab_focus()
		return

	if nickname.length() < 3 or nickname.length() > 20:
		error_label.text = "昵称长度需在3-20字符之间"
		nickname_input.grab_focus()
		return

	if password.length() < 6:
		error_label.text = "密码长度至少6位"
		password_input.grab_focus()
		return

	if password != confirm_password:
		error_label.text = "两次输入的密码不一致"
		confirm_password_input.grab_focus()
		return

	# 调用数据库注册
	var user_id = database.register_user(username, password, gender)
	if user_id != -1:
		register_success.emit(user_id)
		error_label.text = ""  # 清空错误信息
		# 显示主界面
		var main_ui = get_node_or_null("/root/MainUI")
		if main_ui:
				main_ui.visible = true
	else:
		error_label.text = "注册失败，用戶名可能已被使用"
		username_input.grab_focus()
