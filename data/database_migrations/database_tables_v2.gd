# database_tables.gd
class_name DatabaseTablesV2

# database_tables_v2.gd 修改后的 execute() 函数
func execute(database: SQLite) -> bool:
	# 1. 添加允许NULL的updated_at列
	if !database.query("""
		ALTER TABLE story_drafts
		ADD COLUMN updated_at TEXT;
	"""):
		return false

	# 2. 设置现有行的值
	if !database.query("""
		UPDATE story_drafts
		SET updated_at = datetime('now')
		WHERE updated_at IS NULL;
	"""):
		return false

	# 3. 重建表以添加NOT NULL约束
	if !database.query("""
		CREATE TEMPORARY TABLE draft_maps_backup AS SELECT * FROM draft_maps;
		DROP TABLE draft_maps;
		CREATE TABLE draft_maps (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			draft_id INTEGER NOT NULL,
			map_id TEXT NOT NULL,  -- 唯一地图标识
			map_name TEXT NOT NULL DEFAULT '未命名地图',
			description TEXT,
			ai_json_data TEXT NOT NULL,
			processed_data TEXT NOT NULL,
			created_at TEXT NOT NULL DEFAULT (datetime('now')),
			updated_at TEXT NOT NULL DEFAULT (datetime('now')),
			sort_order INTEGER NOT NULL DEFAULT 0,
			cover_path TEXT,
			FOREIGN KEY (draft_id) REFERENCES story_drafts(id)
		);
		INSERT INTO draft_maps SELECT * FROM draft_maps_backup;
		DROP TABLE draft_maps_backup;
	"""):
		return false

	if !database.query("""
		ALTER TABLE story_drafts
		ADD COLUMN cover_path TEXT;
	"""):
		return false	

	# 后续创建draft_maps表的代码保持不变...
	return true
