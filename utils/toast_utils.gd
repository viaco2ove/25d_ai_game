# res://util/toast_utils.gd
extends Node

# 显示自动消失的提示弹窗
static func show_toast(text: String, duration: float = 2.0, parent: Node = null):
	# 如果没有指定父节点，使用场景根节点
	if parent == null:
		push_error("致命错误: parent null ")
		return null

	# 创建弹窗容器
	var container = Control.new()
	container.name = "ToastContainer"
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(container)

	# 创建背景面板
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(300, 80)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	container.add_child(panel)

	# 创建文本标签
	var label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(label)

	# 创建动画效果
	var tween = container.create_tween()
	tween.set_parallel(true)

	# 初始透明状态
	panel.modulate = Color(1, 1, 1, 0)

	# 淡入效果
	tween.tween_property(panel, "modulate", Color(1, 1, 1, 1), 0.3)

	# 等待指定时间
	tween.chain().tween_interval(duration)

	# 淡出效果
	tween.chain().tween_property(panel, "modulate", Color(1, 1, 1, 0), 0.3)

	# 完成后移除节点
	tween.chain().tween_callback(func(): container.queue_free())
