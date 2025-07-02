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
func get_user_drafts_all(user_id: int) -> Array:
	var query = "SELECT id, title, created_at FROM story_drafts WHERE user_id = ? AND status = 'draft';"
	return database.fetch_query(query, [user_id])

# 获取草稿详情
func get_draft(draft_id: int) -> Dictionary:
	var query = "SELECT * FROM story_drafts WHERE id = ?;"
	var result = database.fetch_query(query, [draft_id])
	return result[0] if result.size() > 0 else {}

# 添加删除方法
func delete_draft(draft_id: int) -> bool:
	var query = "UPDATE story_drafts SET deleted = 1 WHERE id = ?"
	return database.execute_query(query, [draft_id])

# 修改查询方法（添加deleted参数）
func get_user_drafts(user_id: int, include_deleted: bool = false) -> Array:
	var query = "SELECT * FROM story_drafts WHERE user_id = ?"
	var bindings = [user_id]

	if !include_deleted:
		query += " AND deleted = 0"

	return database.fetch_query(query, bindings)

# 更新草稿内容
func update_draft_story(draft_id: int, story_data: Dictionary) -> bool:
	var json_data = JSON.stringify(story_data)

	var query = """
		UPDATE story_drafts 
		SET title = ?, description = ?, cover_path = ?, map_data = ?
		WHERE id = ?
	"""

	var params = [
				 story_data.get("title", ""),
				 story_data.get("description", ""),
				 story_data.get("cover_path", ""),
				 json_data,
				 draft_id
				 ]

	return database.execute_query(query, params)
