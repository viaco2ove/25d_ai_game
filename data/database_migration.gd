# database_migration.gd
class_name DatabaseMigration
extends Node
const DB_WANT_VERSION = 2  # 当前数据库版本

var database: SQLite= null

func _init(db: SQLite):
	database = db

func migrate_database():
	# 确保用户数据目录存在
	DirAccess.make_dir_recursive_absolute(OS.get_user_data_dir())
	database.open_db()

	# 创建版本表
	database.query("""
		CREATE TABLE IF NOT EXISTS db_version (
			version INTEGER PRIMARY KEY
		);
	""")

	# 修复版本获取逻辑
	var current_version = 0
	if database.query("""
		SELECT COALESCE(MAX(version), 0) AS current_version 
		FROM db_version;
	"""):
		if database.query_result.size() > 0:
			current_version = database.query_result[0]["current_version"]
		else:
			push_warning("Unexpected empty result from version query")
	else:
		push_warning("Failed to query db_version, using default version 0")

	print("Current database version: ", current_version)

	# 执行版本升级
	if current_version < DB_WANT_VERSION:
		if !upgrade_database(current_version):
			push_error("Database upgrade aborted!")
			database.close_db()
			return

		database.query_with_bindings("""
			INSERT OR REPLACE INTO db_version (version) VALUES (?);
		""", [DB_WANT_VERSION])

	database.close_db()

# database_migration.gd 修改后的 upgrade_database()
func upgrade_database(from_version: int) -> bool:
	print("Upgrading database from version ", from_version, " to ", DB_WANT_VERSION)

	# 开始事务
	if !database.query("BEGIN TRANSACTION;"):
		return false

	for version in range(from_version + 1, DB_WANT_VERSION + 1):
		var script_path = "res://data/database_migrations/database_tables_v%d.gd" % version
		var migration_script = load(script_path)

		if !migration_script:
			push_error("Missing migration script: " + script_path)
			database.query("ROLLBACK;")
			return false

		# 执行迁移并检查结果
		var migration = migration_script.new()
		if !migration.execute(database):
			push_error("Migration failed for version: " + str(version))
			database.query("ROLLBACK;")
			return false

	# 全部成功才提交
	if !database.query("COMMIT;"):
		database.query("ROLLBACK;")
		return false

	return true
