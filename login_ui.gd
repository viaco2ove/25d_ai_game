extends Panel

signal login_success(user_id: int)
signal register_request

@onready var nickname_input: LineEdit = $VBoxContainer/NicknameInput
@onready var password_input: LineEdit = $VBoxContainer/PasswordInput
@onready var error_label: Label = $VBoxContainer/ErrorLabel

var database: Node

func _ready():
	# 获取数据库节点
	database = get_node("/root/data/Database")

	# 连接按钮信号
	$VBoxContainer/HBoxContainer/LoginBtn.pressed.connect(_on_login_btn_pressed)
	$VBoxContainer/HBoxContainer/RegisterBtn.pressed.connect(_on_register_btn_pressed)

	# 回车键登录
	nickname_input.text_submitted.connect(_on_text_submitted)
	password_input.text_submitted.connect(_on_text_submitted)

# 处理输入框回车事件
func _on_text_submitted(_text: String):
	_on_login_btn_pressed()

func _on_login_btn_pressed():
	var nickname = nickname_input.text.strip_edges()
	var password = password_input.text.strip_edges()

	# 输入验证
	if nickname.is_empty():
		error_label.text = "昵称不能为空"
		nickname_input.grab_focus()
		return

	if password.is_empty():
		error_label.text = "密码不能为空"
		password_input.grab_focus()
		return

	# 调用数据库登录
	var user_id = database.login_user(nickname, password)
	if user_id != -1:
		login_success.emit(user_id)
		error_label.text = ""  # 清空错误信息
	else:
		error_label.text = "登录失败，请检查昵称或密码"
		password_input.text = ""  # 清空密码框
		password_input.grab_focus()

func _on_register_btn_pressed():
	register_request.emit()
