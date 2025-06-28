extends Panel

signal register_success(user_id: int)

@onready var nickname_input = $VBoxContainer/NicknameInput
@onready var password_input = $VBoxContainer/PasswordInput
@onready var confirm_password_input = $VBoxContainer/ConfirmPasswordInput
@onready var gender_option = $VBoxContainer/GenderOption
@onready var error_label = $VBoxContainer/ErrorLabel

var database: Node

func _ready():
	database = get_node("/root/data/Database")
	$VBoxContainer/RegisterBtn.pressed.connect(_on_register_btn_pressed)

func _on_register_btn_pressed():
	var nickname = nickname_input.text
	var password = password_input.text
	var confirm_password = confirm_password_input.text
	var gender = gender_option.get_item_text(gender_option.selected)

	if nickname.is_empty() or password.is_empty():
		error_label.text = "昵称和密码不能为空"
		return

	if password != confirm_password:
		error_label.text = "两次输入的密码不一致"
		return

	var user_id = database.register_user(
					  nickname,
					  password,
					  gender
				  )

	if user_id != -1:
		register_success.emit(user_id)
	else:
		error_label.text = "注册失败，请重试"
