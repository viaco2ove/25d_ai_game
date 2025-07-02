# database_tables.gd
class_name DatabaseTablesV3

# database_tables_v2.gd 修改后的 execute() 函数
func execute(database: SQLite) -> bool:
	# 1. 添加允许NULL的updated_at列
	if !database.query("""
		ALTER TABLE story_drafts
		ADD COLUMN deleted INTEGER NOT NULL DEFAULT 0;
	"""):
		return false
		
	# 后续创建draft_maps表的代码保持不变...
	return true
