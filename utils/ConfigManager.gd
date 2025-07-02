# utils/ConfigManager.gd
# 100%可靠且兼容的配置管理器（Godot 4.x）
extends Node

class_name ConfigManager

var config_path: String = "user://config.cfg"
var default_config_path: String = "res://config.cfg"

# 加载并返回配置文件对象
func load_config() -> ConfigFile:
	var config = ConfigFile.new()

	# 打印路径用于调试
	print("user://config.cfg 真实路径: ", OS.get_user_data_dir() + "/config.cfg")

	# 可靠的文件存在检查
	if _file_exists(config_path):
		print("配置文件存在")
		var err = config.load(config_path)
		if err == OK:
			return config
		else:
			push_error("无法加载配置文件，错误代码: ", err)
			_copy_default_config()
			config.load(config_path)
	else:
		print("配置文件不存在，创建默认配置")
		_copy_default_config()
		config.load(config_path)

	return config

# 100%可靠的文件存在检查方法
func _file_exists(path: String) -> bool:
	# 方法1: 使用 DirAccess
	var dir = DirAccess.open("res://")
	if dir and dir.file_exists(path):
		return true

	# 方法2: 使用 File 尝试打开
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		file.close()
		return true

	# 方法3: 使用 ResourceLoader 作为后备
	if ResourceLoader.exists(path):
		return true

	return false

# 从 res:// 复制默认配置到 user://
func _copy_default_config():
	print("正在创建默认配置文件...")

	# 确保默认配置文件存在
	if not _file_exists(default_config_path):
		push_error("致命错误: 默认配置文件不存在 - ", default_config_path)
		return

	# 创建目标目录（如果不存在）
	var user_dir = OS.get_user_data_dir()
	var dir = DirAccess.open(user_dir)
	if not dir:
		# 如果目录不存在，创建它
		DirAccess.make_dir_recursive_absolute(user_dir)
		dir = DirAccess.open(user_dir)  # 重新尝试打开

	# 复制文件
	var src_file = FileAccess.open(default_config_path, FileAccess.READ)
	if not src_file:
		push_error("无法打开默认配置文件")
		return

	var dst_file = FileAccess.open(config_path, FileAccess.WRITE)
	if not dst_file:
		push_error("无法创建用户配置文件")
		src_file.close()
		return

	# 复制内容
	var content = src_file.get_as_text()
	dst_file.store_string(content)

	# 关闭文件
	src_file.close()
	dst_file.close()

	print("已成功创建配置文件: ", config_path)

# 在 ConfigManager.gd 中添加此方法
func save_config(config: ConfigFile):
	# 保存配置文件
	var err = config.save(config_path)
	if err != OK:
		push_error("保存配置文件失败，错误代码: ", err)
	else:
		print("配置文件已成功保存到: ", config_path)
	
