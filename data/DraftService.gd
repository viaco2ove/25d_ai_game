# DraftService.gd - 草稿管理服务
class_name DraftService
extends Node

var database = null

func _init(db):
	database = db

# 创建草稿
func create_draft(user_id: int, title: String = "未命名故事") -> int:
	var now = Time.get_datetime_string_from_system(true)
	var query = "INSERT INTO story_drafts (user_id, title, created_at) VALUES (?, ?, ?);"
	var bindings = [user_id, title, now]

	if database.execute_query(query, bindings):
		return database.db.get_last_insert_rowid()
	return -1

# 获取用户草稿列表
func get_user_drafts(user_id: int) -> Array:
	var query = "SELECT id, title, created_at FROM story_drafts WHERE user_id = ? AND status = 'draft';"
	return database.fetch_query(query, [user_id])

# 获取草稿详情
func get_draft(draft_id: int) -> Dictionary:
	var query = "SELECT * FROM story_drafts WHERE id = ?;"
	var result = database.fetch_query(query, [draft_id])
	return result[0] if result.size() > 0 else {}
