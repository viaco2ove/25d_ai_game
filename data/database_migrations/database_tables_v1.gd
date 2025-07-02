# database_tables.gd
class_name DatabaseTablesV1

func execute(database: SQLite) -> bool:
	# 创建用户表
	if !database.query_with_bindings("""
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
	""",[]): 
		return false

	# 创建草稿表（关联用户ID）
	if !database.query_with_bindings("""
		CREATE TABLE IF NOT EXISTS story_drafts (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			user_id INTEGER NOT NULL,  -- 用户关联字段
			title TEXT NOT NULL DEFAULT '未命名故事',
			created_at TEXT NOT NULL,
			description TEXT,
			map_data TEXT,
			status TEXT NOT NULL DEFAULT 'draft',
			FOREIGN KEY (user_id) REFERENCES users(id)
		);
	""",[]): 
		return false

	return true
