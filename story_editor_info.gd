# story_editor_info.gd
extends CanvasLayer

# 核心功能：故事编辑器，支持多地图创建、AI生成、预览与保存
class_name StoryCreator

# 节点引用（仅保留实际存在的节点）
@onready var hint_label: Label = $DebugPanel/HintLabel  # 提示标签迁移至DebugPanel
@onready var loading_indicator: Control = $LoadingIndicator

@onready var story_panel: Panel = $StoryPanel
@onready var title_edit: LineEdit = $StoryPanel/TitleEdit
@onready var cover_btn: Button = $StoryPanel/CoverBtn
@onready var desc_edit: TextEdit = $StoryPanel/DescEdit

@onready var maps_panel: Panel = $MapsPanel
@onready var add_map_btn: Button = $MapsPanel/AddMapBtn
@onready var map_list: VBoxContainer = $MapsPanel/MapList

@onready var debug_panel: Panel = $DebugPanel
@onready var map_desc_edit: TextEdit = $DebugPanel/MapDescEdit
@onready var ai_data_edit: TextEdit = $DebugPanel/AIDataEdit
@onready var map_data_edit: TextEdit = $DebugPanel/MapDataEdit
@onready var regenerate_btn: Button = $DebugPanel/RegenerateBtn
@onready var preview_btn: Button = $DebugPanel/PreviewBtn
@onready var save_map_btn: Button = $DebugPanel/SaveMapBtn
@onready var exit_debug_btn: Button = $DebugPanel/ExitDebugBtn2

@onready var control_bar: HBoxContainer = $ControlBar
@onready var exit_btn: Button = $ControlBar/ExitBtn
@onready var save_btn: Button = $ControlBar/SaveBtn
@onready var publish_btn: Button = $ControlBar/PublishBtn

# 服务与数据
var map_preview: SubViewportContainer  # 地图预览容器
var ai_service: Node
var database: Node
var user_service: UserService
var draft_service: DraftService

var current_story: Dictionary = {
									"title": "未命名故事",
									"cover_path": "",
									"description": "",
									"maps": []  # 存储多个地图数据
								}
var current_draft_id: int = -1
var current_map_index: int = -1  # 当前调试的地图索引

# 初始化
func _ready():
	_setup_ui_layout()
	_init_services()
	_connect_signals()
	_update_map_list_ui()

# 在 story_editor_info.gd 中添加以下方法
func reset_ui():
	_on_save_btn_pressed()
	"""重置UI到初始状态"""
	# 确保退出调试模式
	show_normal_ui()

	# 重置提示文本
	hint_label.text = "输入自然语言描述（如：一片被迷雾笼罩的魔法森林，远处有积雪的火山）"

	# 隐藏加载指示器
	loading_indicator.visible = false

	# 清空当前编辑状态
	current_map_index = -1

	# 重置表单内容（可选）
	title_edit.text = current_story.title
	desc_edit.text = current_story.description

	# 清空地图列表
	current_story["maps"] = []
	_update_map_list_ui()


# UI 状态管理 ================================================================
func show_normal_ui():
	"""显示正常编辑模式下的UI"""
	debug_panel.visible = false
	story_panel.visible = true
	maps_panel.visible = true
	exit_debug_btn.visible = false

func show_debug_ui():
	"""显示调试模式下的UI"""
	debug_panel.visible = true
	story_panel.visible = false
	maps_panel.visible = false
	exit_debug_btn.visible = true

func hide_all_panels():
	"""隐藏所有主要面板（用于特殊状态）"""
	debug_panel.visible = false
	story_panel.visible = false
	maps_panel.visible = false
	exit_debug_btn.visible = false
	

# 服务初始化
func _init_services():
	ai_service = load("res://services/ai_service_v3.gd").new()
	add_child(ai_service)

	database = get_tree().root.get_node("MainNote/Database")
	user_service = UserService.new(database)
	draft_service = DraftService.new(database)

# 信号连接
func _connect_signals():
	add_map_btn.pressed.connect(_on_add_map_pressed)
	regenerate_btn.pressed.connect(_on_regenerate_pressed)
	preview_btn.pressed.connect(_on_preview_pressed)
	save_map_btn.pressed.connect(_on_save_map_pressed)
	exit_debug_btn.pressed.connect(_on_exit_debug_pressed)
	
	# 连接新按钮的信号
	exit_btn.pressed.connect(_on_exit_btn_pressed)
	save_btn.pressed.connect(_on_save_btn_pressed)
	publish_btn.pressed.connect(_on_publish_btn_pressed)

# 退出编辑器
func _on_exit_btn_pressed():
	# 隐藏编辑器
	visible = false

	# 显示主场景
	var main_scene = get_node("/root/MainNote/MainScene")
	if main_scene:
		main_scene.visible = true

# 保存草稿
func _on_save_btn_pressed():
	if current_draft_id > 0:
		# 更新故事数据
		current_story["title"] = title_edit.text
		current_story["description"] = desc_edit.text

		# 保存到数据库
		draft_service.update_draft_story(current_draft_id, current_story)
		_show_success("草稿已保存!")
	else:
		_show_error("保存失败，草稿ID无效!")

# 发布故事
func _on_publish_btn_pressed():
	if current_draft_id > 0:
		# 验证故事是否完整
		if current_story["title"].strip_edges().is_empty():
			_show_error("故事标题不能为空!")
			return

		if current_story["maps"].is_empty():
			_show_error("请至少添加一个地图!")
			return

		# 将草稿转为正式故事
		var story_id = draft_service.publish_draft(current_draft_id)

		if story_id > 0:
			_show_success("故事发布成功! ID: %d" % story_id)
			# 重置编辑器
			reset_ui()
		else:
			_show_error("发布失败，请重试!")
	else:
		_show_error("发布失败，草稿ID无效!")


# UI布局初始化
func _setup_ui_layout():
	exit_debug_btn.visible = false
	loading_indicator.visible = false
	show_normal_ui()  # 使用函数设置初始UI状态
	
	hint_label.text = "输入自然语言描述（如：一片被迷雾笼罩的魔法森林，远处有积雪的火山）"

	# 卡片式UI样式
	var card_style = StyleBoxFlat.new()
	card_style.bg_color = Color(0.12, 0.14, 0.18)
	card_style.shadow_size = 6
	card_style.shadow_color = Color(0, 0, 0, 0.3)
	debug_panel.add_theme_stylebox_override("panel", card_style)

# 地图管理 =====================================================================
func _on_add_map_pressed():
	var new_map = {
					  "map_name": "未命名地图",
					  "description": "一片被迷雾笼罩的魔法森林，远处有积雪的火山，山下有河流，还有村庄",
					  "ai_json_data": {},
					  "processed_data": {},
					  "sort_order": current_story["maps"].size()
				  }
	current_story["maps"].append(new_map)
	_update_map_list_ui()

func _update_map_list_ui():
	# 清除旧项
	for child in map_list.get_children():
		child.queue_free()

	# 动态生成地图项
	for i in range(current_story["maps"].size()):
		var map_data = current_story["maps"][i]
		var map_item = HBoxContainer.new()
		map_item.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		# 地图名称编辑
		var name_edit = LineEdit.new()
		name_edit.text = map_data["map_name"]
		name_edit.placeholder_text = "地图名称"
		name_edit.text_changed.connect(func(text):current_story["maps"][i]["map_name"] = text)

		# 调试按钮
		var debug_btn = Button.new()
		debug_btn.text = "调试"
		debug_btn.pressed.connect(func(): enter_debug_mode(i))

		# 删除按钮
		var delete_btn = Button.new()
		delete_btn.text = "删除"
		delete_btn.pressed.connect(func():
			current_story["maps"].remove_at(i)  # 缩进 4 空格或 1 制表符
			_update_map_list_ui()			   # 缩进 4 空格或 1 制表符
		)

		map_item.add_child(name_edit)
		map_item.add_child(debug_btn)
		map_item.add_child(delete_btn)
		map_list.add_child(map_item)

# 调试模式 =====================================================================
func enter_debug_mode(map_index: int):
	current_map_index = map_index
	var map_data = current_story["maps"][map_index]

	map_desc_edit.text = map_data["description"]
	ai_data_edit.text = JSON.stringify(map_data["ai_json_data"], "\t")
	map_data_edit.text = JSON.stringify(map_data["processed_data"], "\t")

	# 切换面板可见性
	show_debug_ui()  # 使用函数显示调试UI

func _on_exit_debug_pressed():
	show_normal_ui()  # 使用函数返回正常UI状态

	if map_preview:
		map_preview.reset_viewport()
		map_preview._clear_current_map()
		map_preview.cam.position = Vector3(0, 20, 15)
		map_preview.cam.rotation_degrees = Vector3(-70, 0, 0)

	hint_label.text = "已退出预览模式"
	hint_label.add_theme_color_override("font_color", Color.WHITE)

# AI与数据处理 =================================================================
func _on_regenerate_pressed():
	var description = map_desc_edit.text.strip_edges()
	if description.is_empty():
		_show_error("请输入地图描述!")
		return

	show_loading()
	regenerate_btn.disabled = true

	# 异步调用AI服务
	var terrain_data = await ai_service.analyze_terrain(description)
	hide_loading()
	regenerate_btn.disabled = false

	if terrain_data.is_empty():
		_show_error("AI生成失败，请重试!")
		return

	# 更新地图数据
	var map_data = current_story["maps"][current_map_index]
	map_data["ai_json_data"] = terrain_data
	map_data["processed_data"] = _convert_ai_data(terrain_data)

	ai_data_edit.text = JSON.stringify(terrain_data, "\t")
	map_data_edit.text = JSON.stringify(map_data["processed_data"], "\t")
	_show_success("AI数据已重新生成!")

func _convert_ai_data(ai_data: Dictionary) -> Dictionary:
	var map_data = {
					   "biome": ai_data.get("biome", {}),
					   "elements": [],
					   "atmosphere": ai_data.get("atmosphere", {})
				   }

	for element in ai_data.get("elements", []):
		map_data["elements"].append({
			"type": element["mode_type"],
			"name": element["mode_name"],
			"position": Vector3(element["position"]["x"], 0, element["position"]["z"]),
			"size": Vector2(element["size"]["width"], element["size"]["depth"]),
			"rotation": element.get("rotation", 0)
		})
	return map_data

# 预览与保存 ===================================================================
func _on_preview_pressed():
	var map_data = current_story["maps"][current_map_index]
	var preview_data = _parse_edited_data(map_data_edit.text)

	if preview_data.is_empty():
		_show_error("无法生成预览，数据为空!")
		return

	# 延迟生成避免卡顿
	call_deferred("_generate_preview", preview_data)

func _generate_preview(data: Dictionary):
	if map_preview:
		map_preview._clear_current_map()  # 再删除节点
		map_preview.generate_from_data(data)
		_show_success("预览已生成!")
	else:
		push_error("MapPreview节点未初始化")

func _on_save_map_pressed():
	var map_data = current_story["maps"][current_map_index]
	map_data["description"] = map_desc_edit.text.strip_edges()

	# 解析编辑后的数据
	if !ai_data_edit.text.strip_edges().is_empty():
		map_data["ai_json_data"] = _parse_edited_data(ai_data_edit.text)
	if !map_data_edit.text.strip_edges().is_empty():
		map_data["processed_data"] = _parse_edited_data(map_data_edit.text)

	# 保存整个故事
	if current_draft_id > 0:
		draft_service.update_draft_story(current_draft_id, current_story)
		_show_success("地图数据已保存!")
	else:
		_show_error("保存失败，草稿ID无效!")

# 工具函数 =====================================================================
func _parse_edited_data(text: String) -> Dictionary:
	var json = JSON.new()
	return json.get_data() if json.parse(text) == OK else {}

func show_loading():
	loading_indicator.visible = true

func hide_loading():
	loading_indicator.visible = false

func _show_error(message: String):
	hint_label.text = message
	hint_label.add_theme_color_override("font_color", Color.RED)

func _show_success(message: String):
	hint_label.text = message
	hint_label.add_theme_color_override("font_color", Color.GREEN)

func safe_get_string(data: Dictionary, key: String, default: String = "") -> String:
	var value = data.get(key)
	return str(value) if value != null else default
	
# 草稿加载 =====================================================================
func load_draft(draft_id: int):
	current_draft_id = draft_id
	var draft_data = draft_service.get_draft(draft_id)

	if draft_data:
		title_edit.text = safe_get_string(draft_data, "title", "未命名故事")
		desc_edit.text = safe_get_string(draft_data, "description")

		# 加载地图数据
		if draft_data.has("maps"):
			current_story["maps"] = draft_data["maps"]
			_update_map_list_ui()
