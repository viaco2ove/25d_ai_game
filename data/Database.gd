# /data/Database.gd - 数据库服务层 (Godot 4.4.1)
extends Node

# 修复点：取消注释并修正预加载路径
#var SQLite = preload("res://addons/godot-sqlite/bin/gdsqlite.gdns")
const DB_PATH = "user://story_drafts.db"
var db: SQLite = null  # 仅声明变量，不注解类型
var is_ready = false
var database_migration: DatabaseMigration

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
	database_migration = DatabaseMigration.new(db)
	database_migration.migrate_database();
	is_ready = true

func execute_query(query: String, bindings: Array = []) -> bool:
	db.open_db()
	var success = db.query_with_bindings(query, bindings)
	db.close_db()
	return success

func fetch_query(query: String, bindings: Array = []) -> Array:
	db.open_db()
	if db.query_with_bindings(query, bindings):
		var result = db.query_result
		db.close_db()
		return result
	db.close_db()
	return []
