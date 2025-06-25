# canvas_layer.gd -》StoryCreator（CanvasLayer）
extends CanvasLayer

# 节点引用
@onready var input_panel: Panel = $InputPanel
@onready var text_edit: TextEdit = $InputPanel/TextEdit
@onready var debug_btn: Button = $InputPanel/DebugBtn
@onready var hint_label: Label = $InputPanel/HintLabel
@onready var loading_indicator: Control = $LoadingIndicator
@onready var exit_debug_btn: Button = $ExitDebugBtn  # 浮动退出按钮

var map_preview: SubViewportContainer
var ai_service: Node
var is_debug_mode: bool = false  # 调试模式标志

func _ready():
	# UI初始化
	debug_btn.pressed.connect(_on_generate_pressed)
	exit_debug_btn.pressed.connect(_on_exit_debug_pressed)
	text_edit.text_changed.connect(_on_text_changed)
	_setup_ui_layout()

	# 初始化AI服务
	ai_service = load("res://services/ai_service_v3.gd").new()
	add_child(ai_service)

	# 设置初始UI状态
	exit_debug_btn.visible = false  # 初始隐藏退出按钮
	loading_indicator.visible = false
	hint_label.text = "输入自然语言描述（如：一片被迷雾笼罩的魔法森林，远处有积雪的火山）"

#	show_loading()
	

# 在 canvas_layer.gd 中添加
func show_loading():
	loading_indicator.visible = true
	print("LOADING STARTED: ", loading_indicator.visible)

func hide_loading():
	loading_indicator.visible = false
# 可以在这里停止动画

func _setup_ui_layout():
	# 卡片式UI样式
	var card_style = StyleBoxFlat.new()
	card_style.bg_color = Color(0.12, 0.14, 0.18)
	card_style.shadow_size = 6
	card_style.shadow_color = Color(0, 0, 0, 0.3)
	input_panel.add_theme_stylebox_override("panel", card_style)

	# 配置浮动退出按钮
	exit_debug_btn.text = "退出预览"
	exit_debug_btn.position = Vector2(20, 20)  # 左上角位置
	exit_debug_btn.size = Vector2(120, 40)
	exit_debug_btn.add_theme_font_size_override("font_size", 16)

func _set_debug_mode(active: bool):
	is_debug_mode = active
	input_panel.visible = !active  # 调试时隐藏输入面板
	exit_debug_btn.visible = active  # 调试时显示退出按钮

	# 控制地图预览渲染
	if map_preview:
		map_preview.set_render_enabled(active)

func _on_generate_pressed() -> void:
	if text_edit.text.strip_edges().is_empty():
		hint_label.text = "请输入描述内容!"
		hint_label.add_theme_color_override("font_color", Color.RED)
		return

	# 显示加载状态
	show_loading()  # 使用统一方法控制加载状态
	debug_btn.disabled = true

	# 调用AI服务解析语义
	var terrain_data = await ai_service.analyze_terrain(text_edit.text)
	
	# 隐藏加载状态
	hide_loading()  # 使用统一方法隐藏

	debug_btn.disabled = false

	if terrain_data.is_empty():
		hint_label.text = "生成失败，请重试!"
		hint_label.add_theme_color_override("font_color", Color.RED)
		return

	if map_preview:
		# 进入调试模式
		_set_debug_mode(true)
		# 生成地图
		map_preview.generate_from_data(terrain_data)
	else:
		push_error("MapPreview节点未找到!")

func _on_exit_debug_pressed() -> void:
	_set_debug_mode(false)
	print("_on_exit_debug_pressed ")
	hint_label.text = "正在退出预览..."
	
	if map_preview:
		map_preview.reset_viewport()  # 先重置视口
		map_preview._clear_current_map()  # 再删除节点
		# 确保相机重置（防止偏移导致黑屏）
		map_preview.cam.position = Vector3(0, 20, 15)
		map_preview.cam.rotation_degrees = Vector3(-70, 0, 0)
		
	# 4. 重置UI状态
	hint_label.add_theme_color_override("font_color", Color.WHITE)
	

func _on_text_changed():
	# 输入时自动调整文本框大小
	var line_count = text_edit.get_line_count()
	text_edit.custom_minimum_size.y = max(200, line_count * 20)

	# 重置提示文本颜色
	hint_label.add_theme_color_override("font_color", Color.WHITE)
