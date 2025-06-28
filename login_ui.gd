extends Panel

signal login_success(user_id: int)
signal register_request

@onready var nickname_input = $VBoxContainer/NicknameInput
@onready var password_input = $VBoxContainer/PasswordInput
@onready var error_label = $VBoxContainer/ErrorLabel

var database: Node

func _ready():
	database = get_node("/root/data/Database")
	$VBoxContainer/HBoxContainer/LoginBtn.pressed.connect(_on_login_btn_pressed)
	$VBoxContainer/HBoxContainer/RegisterBtn.pressed.connect(_on_register_btn_pressed)

func _on_login_btn_pressed():
	var nickname = nickname_input.text
	var password = password_input.text

	if nickname.is_empty() or password.is_empty():
		error_label.text = "昵称和密码不能为空"
		return

	var user_id = database.login_user(nickname, password)
	if user_id != -1:
		login_success.emit(user_id)
	else:
		error_label.text = "登录失败，请检查昵称或密码"

func _on_register_btn_pressed():
	register_request.emit()
