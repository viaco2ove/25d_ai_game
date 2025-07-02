#draft_list.gd
extends Panel

signal draft_selected_edit(draft_id: int)

var database: Node
var current_user_id: int = -1
var user_service: UserService
var draft_service: DraftService

# 按钮引用
@onready var edit_btn: Button = $VBoxContainer/ButtonContainer/EditBtn
@onready var delete_btn: Button = $VBoxContainer/ButtonContainer/DeleteBtn
@onready var batch_delete_btn: Button = $VBoxContainer/ButtonContainer/BatchDeleteBtn
@onready var back_btn: Button = $VBoxContainer/ButtonContainer/BackBtn

# 选择状态
var selected_draft_id: int = -1
var multi_selected_ids: Array = []

func _ready():
	database = get_tree().root.get_node("MainNote/Database")
	back_btn.pressed.connect(_on_back_pressed)

	# 初始化业务服务
	user_service = UserService.new(database)
	draft_service = DraftService.new(database)

	# 连接操作按钮信号
	edit_btn.pressed.connect(_on_edit_pressed)
	delete_btn.pressed.connect(_on_delete_pressed)
	batch_delete_btn.pressed.connect(_on_batch_delete_pressed)

	# 初始禁用操作按钮
	_update_button_states()

# 设置当前用户ID并加载草稿
func set_user_id(user_id: int):
	current_user_id = user_id
	load_drafts()

# 加载用户草稿
func load_drafts():
	if current_user_id == -1:
		return

	# 重置选择状态
	selected_draft_id = -1
	multi_selected_ids.clear()

	# 获取未删除的草稿
	var drafts = draft_service.get_user_drafts(current_user_id, false)
	$VBoxContainer/DraftList.clear()

	for draft in drafts:
		var title = draft.get("title", "未命名草稿")
		var text = title + " - " + draft.get("created_at", "")
		$VBoxContainer/DraftList.add_item(text)

		# 将草稿ID存储在metadata中
		var index = $VBoxContainer/DraftList.get_item_count() - 1
		$VBoxContainer/DraftList.set_item_metadata(index, draft["id"])

	# 连接选择信号
	$VBoxContainer/DraftList.item_selected.connect(_on_draft_selected)

	# 更新按钮状态
	_update_button_states()

# 草稿项被选中
func _on_draft_selected(index: int):
	selected_draft_id = $VBoxContainer/DraftList.get_item_metadata(index)

	# 更新多选数组（获取所有选中项）
	multi_selected_ids = $VBoxContainer/DraftList.get_selected_items().map(
		func(idx):
			return $VBoxContainer/DraftList.get_item_metadata(idx)
			)

	# 更新按钮状态
	_update_button_states()

# 更新操作按钮状态
func _update_button_states():
	# 编辑和删除按钮需要单选有效
	edit_btn.disabled = selected_draft_id == -1
	delete_btn.disabled = selected_draft_id == -1

	# 批量删除需要至少一个选中项
	batch_delete_btn.disabled = multi_selected_ids.is_empty()

# 编辑按钮处理
func _on_edit_pressed():
	if selected_draft_id != -1:

		# 创建确认对话框
		var dialog = ConfirmationDialog.new()
		dialog.title = "确认删除"
		dialog.dialog_text = "确定要删除这个草稿吗？此操作不可恢复！"
	
		# 确认回调
		dialog.confirmed.connect(
				func():
					# 隐藏当前界面
					visible = false
					# 触发选择信号
					draft_selected_edit.emit(selected_draft_id)
		
					dialog.queue_free()
		)
		
		# 取消回调
		dialog.canceled.connect(
				func():
					dialog.queue_free()
		)
		
		add_child(dialog)
		dialog.popup_centered()

# 删除单个草稿（带确认）
func _on_delete_pressed():
	if selected_draft_id == -1:
		return

	# 创建确认对话框
	var dialog = ConfirmationDialog.new()
	dialog.title = "确认删除"
	dialog.dialog_text = "确定要删除这个草稿吗？此操作不可恢复！"

	# 确认回调
	dialog.confirmed.connect(
		func():
			if draft_service.delete_draft(selected_draft_id):
				# 刷新列表
				load_drafts()
			else:
				push_error("删除草稿失败")
			dialog.queue_free()
	)

	# 取消回调
	dialog.canceled.connect(
		func():
			dialog.queue_free()
	)

	add_child(dialog)
	dialog.popup_centered()

# 批量删除（带确认）
func _on_batch_delete_pressed():
	if multi_selected_ids.is_empty():
		return

	# 创建确认对话框
	var dialog = ConfirmationDialog.new()
	dialog.title = "确认批量删除"
	dialog.dialog_text = "确定要删除选中的 %d 个草稿吗？此操作不可恢复！" % multi_selected_ids.size()

	# 确认回调
	dialog.confirmed.connect(
		func():
			var success_count = 0
			for id in multi_selected_ids:
				if draft_service.delete_draft(id):
					success_count += 1

			# 显示操作结果
			if success_count > 0:
				load_drafts()  # 刷新列表
			else:
				push_error("批量删除失败")

			dialog.queue_free()
	)

	# 取消回调
	dialog.canceled.connect(
		func():
			dialog.queue_free()
	)

	add_child(dialog)
	dialog.popup_centered()

# 返回按钮
func _on_back_pressed():
	queue_free()
