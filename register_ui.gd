extends Panel

signal register_success(user_id: int)

@onready var nickname_input: LineEdit = $VBoxContainer/NicknameInput
@onready var password_input: LineEdit = $VBoxContainer/PasswordInput
@onready var confirm_password_input: LineEdit = $VBoxContainer/ConfirmPasswordInput
@onready var gender_option: OptionButton = $VBoxContainer/GenderOption
@onready var error_label: Label = $VBoxContainer/ErrorLabel
@onready var register_btn: Button = $VBoxContainer/RegisterBtn

var database: Node

func _ready():
	database = get_node("/root/data/Database")
	register_btn.pressed.connect(_on_register_btn_pressed)

	# 回车键提交
	nickname_input.text_submitted.connect(_on_text_submitted)
	password_input.text_submitted.connect(_on_text_submitted)
	confirm_password_input.text_submitted.connect(_on_text_submitted)

func _on_text_submitted(_text: String):
	_on_register_btn_pressed()

func _on_register_btn_pressed():
	var nickname = nickname_input.text.strip_edges()
	var password = password_input.text.strip_edges()
	var confirm_password = confirm_password_input.text.strip_edges()
	var gender = gender_option.get_item_text(gender_option.selected)

	# 输入验证
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
	var user_id = database.register_user(nickname, password, gender)
	if user_id != -1:
		register_success.emit(user_id)
		error_label.text = ""  # 清空错误信息
	else:
		error_label.text = "注册失败，昵称可能已被使用"
		nickname_input.grab_focus()
