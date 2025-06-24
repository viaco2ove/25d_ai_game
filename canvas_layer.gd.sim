# StoryCreator.gd
extends CanvasLayer

# 节点引用
@onready var text_edit: TextEdit = $InputPanel/TextEdit
@onready var debug_btn: Button = $InputPanel/DebugBtn
@onready var hint_label: Label = $InputPanel/HintLabel

var map_preview: SubViewportContainer

func _ready():
	# UI初始化
	debug_btn.pressed.connect(_on_generate_pressed)
	text_edit.text_changed.connect(_on_text_changed)
	_setup_ui_layout()

	# 移动端适配
	if OS.has_feature("mobile"):
		debug_btn.custom_minimum_size = Vector2(80, 80)

func _setup_ui_layout():
	# 创建卡片式UI样式
	var card_style = StyleBoxFlat.new()
	card_style.bg_color = Color(0.12, 0.14, 0.18)
	card_style.shadow_size = 6
	card_style.shadow_color = Color(0, 0, 0, 0.3)
	$InputPanel.add_theme_stylebox_override("panel", card_style)

	# 设置提示文本
	hint_label.text = "提示：输入包含地形关键词(森林/山脉/河流等)，按回车生成预览"

func _on_generate_pressed():
	if map_preview:
		# 调用MapPreview的生成接口
		map_preview.generate_map(text_edit.text)
	else:
		push_error("MapPreview节点未找到!")

func _on_text_changed():
	# 输入时自动调整文本框大小
	var line_count = text_edit.get_line_count()
	text_edit.custom_minimum_size.y = max(200, line_count * 20)
