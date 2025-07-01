# /data/Database.gd - 数据库服务层 (Godot 4.4.1)
extends Node

# 修复点：取消注释并修正预加载路径
#var SQLite = preload("res://addons/godot-sqlite/bin/gdsqlite.gdns")
const DB_PATH = "user://story_drafts.db"
var db: SQLite = null  # 仅声明变量，不注解类型
var is_ready = false

func _ready():
	print("Database node initialized! Path: ", get_path())
	init_db()

func init_db():
	# 原有代码保持不变...
	db = SQLite.new()
	db.path = DB_PATH

	print("User data dir: ", OS.get_user_data_dir())
	if FileAccess.file_exists(DB_PATH):
		print("DB file exists.")
	
	db.open_db()

	# 创建草稿表（关联用户ID）
	db.query_with_bindings("""
		CREATE TABLE IF NOT EXISTS story_drafts (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			user_id INTEGER NOT NULL,  -- 新增用户关联字段
			title TEXT NOT NULL DEFAULT '未命名故事',
			created_at TEXT NOT NULL,
			description TEXT,
			map_data TEXT,
			status TEXT NOT NULL DEFAULT 'draft',
			FOREIGN KEY (user_id) REFERENCES users(id)
		);
	""", [])

	# 创建用户表
	db.query_with_bindings("""
		CREATE TABLE IF NOT EXISTS users (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			username TEXT NOT NULL UNIQUE,
			nickname TEXT NOT NULL,
			gender TEXT CHECK(gender IN ('male', 'female', 'other')),
			preferences TEXT,  -- JSON数组存储多选偏好
			phone TEXT UNIQUE,
			email TEXT UNIQUE,
			avatar_path TEXT,  -- 头像文件路径
			password_hash TEXT NOT NULL  -- 加密存储
		);
	""", [])
	db.close_db()

	is_ready = true
	
func is_initialized():
	return is_ready

# ---------- 用户管理功能 ----------
# 注册新用户（返回用户ID或-1失败）
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
	db.open_db()

	# 密码加密（SHA-256）
	var ctx = HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(password.to_utf8_buffer())
	var password_hash = ctx.finish().hex_encode()

	var query = """
		INSERT INTO users (username,nickname, gender, preferences, phone, email, avatar_path, password_hash)
		VALUES (?,?, ?, ?, ?, ?, ?, ?);
	"""
	var bindings = [
				username,
				nickname,
				gender,
				JSON.stringify(preferences),  # 偏好转为JSON数组
				phone,
				email,
				avatar_path,
				password_hash
				]

	if db.query_with_bindings(query, bindings) :
		var user_id = db.get_last_insert_rowid()
		db.close_db()
		return user_id
	else:
		push_error("User registration failed: " + db.error_message)
		db.close_db()
		return -1

# 用户登录验证（返回用户ID或-1失败）
func login_user(username: String, password: String) -> int:
	db.open_db()
	var query = "SELECT id, password_hash FROM users WHERE username = ?;"
	var bindings = [username]

	if db.query_with_bindings(query, bindings)  and db.query_result.size() > 0:
		var user_data = db.query_result[0]

		# 密码加密（SHA-256）
		var ctx = HashingContext.new()
		ctx.start(HashingContext.HASH_SHA256)
		ctx.update(password.to_utf8_buffer())
		var password_hash = ctx.finish().hex_encode()
		

		if password_hash == user_data["password_hash"]:
			db.close_db()
			return user_data["id"]

	db.close_db()
	return -1  # 登录失败

# 更新用户信息（如头像、偏好等）
func update_user_profile(
	user_id: int,
	avatar_path: String = "",
	preferences: Array = [],
	phone: String = "",
	email: String = ""
) -> bool:
	db.open_db()
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
		return false  # 无更新内容

	var query = "UPDATE users SET " + ", ".join(updates) + " WHERE id = ?;"
	bindings.append(user_id)

	var success = db.query_with_bindings(query, bindings) 
	if !success:
		push_error("Update user profile failed: " + db.error_message)
	db.close_db()
	return success

# ---------- 草稿功能扩展（关联用户ID）----------
# 创建草稿时关联用户
func create_draft(user_id: int, title: String = "未命名故事") -> int:
	db.open_db()
	var now = Time.get_datetime_string_from_system(true)
	var query = "INSERT INTO story_drafts (user_id, title, created_at) VALUES (?, ?, ?);"
	var bindings = [user_id, title, now]

	if db.query_with_bindings(query, bindings) :
		var draft_id = db.get_last_insert_rowid()
		db.close_db()
		return draft_id
	else:
		push_error("Create draft failed: " + db.error_message)
		db.close_db()
		return -1

# 获取用户专属草稿列表
func get_user_drafts(user_id: int) -> Array:
	db.open_db()
	var query = "SELECT id, title, created_at FROM story_drafts WHERE user_id = ? AND status = 'draft';"
	var bindings = [user_id]

	if db.query_with_bindings(query, bindings) :
		var result = db.query_result
		db.close_db()
		return result
	else:
		push_error("Query drafts failed: " + db.error_message)
		db.close_db()
		return []

func get_user_info(user_id: int) -> Dictionary:
	db.open_db()
	var query = "SELECT * FROM users WHERE id = ?;"
	var bindings = [user_id]
	
	if db.query_with_bindings(query, bindings)  and db.query_result.size() > 0:
		var user_data = db.query_result[0]
		db.close_db()
		return user_data
	
	db.close_db()
	return {}

# 获取用户完整信息（用于个人页面）
func get_full_user_data(user_id: int) -> Dictionary:
	db.open_db()
	var query = "SELECT * FROM users WHERE id = ?;"
	if db.query_with_bindings(query, [user_id])  and db.query_result.size() > 0:
		var data = db.query_result[0]
		data["preferences"] = JSON.parse_string(data["preferences"])  # JSON转数组
		return data
	return {}

# 获取草稿详情
func get_draft(draft_id: int) -> Dictionary:
	db.open_db()
	var query = "SELECT * FROM story_drafts WHERE id = ?;"
	var bindings = [draft_id]

	if db.query_with_bindings(query, bindings)  and db.query_result.size() > 0:
		var draft = db.query_result[0]
		db.close_db()
		return draft

	db.close_db()
	return {}
