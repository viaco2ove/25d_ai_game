# UserService.gd - 用户管理服务
class_name UserService
extends Node

var database = null

func _init(db):
	database = db

# 注册新用户
func register_user(
	username: String,
	nickname: String,
	password: String,
	gender: String = "other",
	preferences: Array = [],
	phone: String = "",
	email: String = "",
	avatar_path: String = ""
) -> int:
	var ctx = HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(password.to_utf8_buffer())
	var password_hash = ctx.finish().hex_encode()

	var query = """
		INSERT INTO users (username, nickname, gender, preferences, phone, email, avatar_path, password_hash)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?);
	"""
	var bindings = [
				username,
				nickname,
				gender,
				JSON.stringify(preferences),
				phone,
				email,
				avatar_path,
				password_hash
				]

	if database.execute_query(query, bindings):
		return database.db.get_last_insert_rowid()
	return -1

# 用户登录验证
func login_user(username: String, password: String) -> int:
	var query = "SELECT id, password_hash FROM users WHERE username = ?;"
	var bindings = [username]
	var result = database.fetch_query(query, bindings)

	if result.size() > 0:
		var user_data = result[0]
		var ctx = HashingContext.new()
		ctx.start(HashingContext.HASH_SHA256)
		ctx.update(password.to_utf8_buffer())
		var password_hash = ctx.finish().hex_encode()

		if password_hash == user_data["password_hash"]:
			return user_data["id"]
	return -1

# 获取用户信息
func get_user_info(user_id: int) -> Dictionary:
	var query = "SELECT * FROM users WHERE id = ?;"
	var result = database.fetch_query(query, [user_id])
	return result[0] if result.size() > 0 else {}

# 更新用户信息
func update_user_profile(
	user_id: int,
	avatar_path: String = "",
	preferences: Array = [],
	phone: String = "",
	email: String = ""
) -> bool:
	var updates = []
	var bindings = []

	if avatar_path != "":
		updates.append("avatar_path = ?")
		bindings.append(avatar_path)
	if preferences.size() > 0:
		updates.append("preferences = ?")
		bindings.append(JSON.stringify(preferences))
	if phone != "":
		updates.append("phone = ?")
		bindings.append(phone)
	if email != "":
		updates.append("email = ?")
		bindings.append(email)

	if updates.size() == 0:
		return false

	var query = "UPDATE users SET " + ", ".join(updates) + " WHERE id = ?;"
	bindings.append(user_id)
	return database.execute_query(query, bindings)


	
