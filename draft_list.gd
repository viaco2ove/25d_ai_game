#draft_list.gd
extends Panel

signal draft_selected_edit(draft_id: int)

var database: Node
var current_user_id: int = -1
var user_service: UserService
var draft_service: DraftService

# 按钮引用
@onready var batch_delete_btn: Button = $VBoxContainer/ButtonContainer/BatchDeleteBtn
@onready var back_btn: Button = $VBoxContainer/ButtonContainer/BackBtn
@onready var draft_tree: Tree = $VBoxContainer/DraftList

# 选择状态
var selected_draft_id: int = -1
var multi_selected_ids: Array = []
var action_container_template: HBoxContainer


func _ready():
	database = get_tree().root.get_node("MainNote/Database")
	back_btn.pressed.connect(_on_back_pressed)

	# 初始化业务服务
	user_service = UserService.new(database)
	draft_service = DraftService.new(database)

	# 连接操作按钮信号
	batch_delete_btn.pressed.connect(_on_batch_delete_pressed)
	draft_tree.item_selected.connect(_on_draft_selected)
	draft_tree.empty_clicked.connect(_on_empty_clicked)

	# 连接树控件按钮点击信号
	draft_tree.button_clicked.connect(_on_tree_button_clicked)
#	// 输出 true 表示连接成功
	print(draft_tree.button_clicked.is_connected(_on_tree_button_clicked))  
# 设置当前用户ID并加载草稿
func set_user_id(user_id: int):
	current_user_id = user_id
	load_drafts()

# 加载用户草稿
# 加载草稿
func load_drafts():
	if current_user_id == -1:
		return

	draft_tree.clear()
	draft_tree.columns = 3
	draft_tree.set_column_title(0, "选择")
	draft_tree.set_column_title(1, "标题")
	draft_tree.set_column_title(2, "操作")
	draft_tree.set_column_expand(0, false)
	draft_tree.set_column_expand(1, true)
	draft_tree.set_column_expand(2, false)
	draft_tree.set_column_custom_minimum_width(0, 40)
	draft_tree.set_column_custom_minimum_width(2, 80)
#	确保 Tree 拦截点击
	draft_tree.mouse_filter = Control.MOUSE_FILTER_STOP

	var drafts = draft_service.get_user_drafts(current_user_id, false)
	var root = draft_tree.create_item()
	
	print("Draft tree is inside tree: ", draft_tree.is_inside_tree())
	for draft in drafts:
		var item = draft_tree.create_item(root)
		# 添加复选框
		item.set_cell_mode(0, TreeItem.CELL_MODE_CHECK)
		item.set_checked(0, false)
		item.set_editable(0, true)

		# 标题和日期
		var title = draft.get("title", "未命名草稿")
		var text = title + " - " + draft.get("created_at", "")
		item.set_text(1, text)
		item.set_metadata(0, draft["id"])
	
		var edit_icon = resize_texture( preload("res://image/pencil-square.svg"),32, 32)
	
		var delete_icon = resize_texture(preload("res://image/trash3.svg"),32, 32)
	
		var slash_icon =  resize_texture(preload("res://image/slash-lg.svg"),3, 16)
	
		item.add_button(2, delete_icon,0,false, "删除")
		item.add_button(2, slash_icon, 1,true, "")
		item.add_button(2,edit_icon, 2,false, "编辑")

func _on_item_checked(column: int, checked: bool, item: TreeItem):
	var draft_id = item.get_metadata(0)
	if checked:
		if not multi_selected_ids.has(draft_id):
			multi_selected_ids.append(draft_id)
	else:
		multi_selected_ids.erase(draft_id)
	_update_button_states() 		
	
func resize_texture(texture: Texture2D, width: int, height: int) -> Texture2D:
	var img = texture.get_image()
	img.resize(width, height, Image.INTERPOLATE_LANCZOS)  # 高质量缩放
	var new_texture = ImageTexture.create_from_image(img)
	return new_texture
	
# 处理树控件按钮点击
func _on_tree_button_clicked(item: TreeItem, column: int, button_id: int, mouse_button_index: int):
	# 确保是在操作列（第2列）且是左键点击
	if column != 2 or mouse_button_index != MOUSE_BUTTON_LEFT:
		return

	# 获取草稿ID
	var draft_id = item.get_metadata(0)

	# 根据按钮ID执行操作
	match button_id:
		2:  # 编辑按钮
			selected_draft_id = draft_id
			_on_edit_pressed()
		0:  # 删除按钮
			selected_draft_id = draft_id
			_on_delete_pressed()

			
# 处理空白区域点击
func _on_empty_clicked(position: Vector2, mouse_button_index: int):
	draft_tree.deselect_all()
	_update_button_states()
	
func _make_edit_callback(id):
	return func():
		selected_draft_id = id
		_on_edit_pressed()

func _make_delete_callback(id):
	return func():
		selected_draft_id = id
		_on_delete_pressed()

# 草稿项被选中
func _on_draft_selected():
	# 获取当前选中的 TreeItem
	var selected_item = draft_tree.get_selected()

	if selected_item:
		selected_item.set_checked(0, true)  # 第0列是复选框
		# 从 TreeItem 获取元数据
		selected_draft_id = selected_item.get_metadata(0)

		# 更新多选数组
		multi_selected_ids = []
		var next_selected = draft_tree.get_next_selected(null)
		while next_selected != null:
			multi_selected_ids.append(next_selected.get_metadata(0))
			next_selected = draft_tree.get_next_selected(next_selected)

	# 更新按钮状态
	_update_button_states()

# 更新操作按钮状态
func _update_button_states():
	var selected_ids = _get_selected_draft_ids()
	batch_delete_btn.disabled = selected_ids.is_empty()

# 获取选中的草稿ID
func _get_selected_draft_ids() -> Array:
	var ids = []
	var selected_item = draft_tree.get_next_selected(null)
	while selected_item != null:
		ids.append(selected_item.get_metadata(0))
		selected_item = draft_tree.get_next_selected(selected_item)
	return ids


# 获取勾选的草稿ID
func _get_checked_draft_ids() -> Array:
	var ids = []
	var root = draft_tree.get_root()
	if root:
		var child = root.get_first_child()
		while child:
			if child.is_checked(0):
				ids.append(child.get_metadata(0))
			child = child.get_next()
	return ids
	
# 编辑按钮处理
func _on_edit_pressed():
	if selected_draft_id != -1:

		# 创建确认对话框
		var dialog = ConfirmationDialog.new()
		dialog.title = "确认编辑"
		dialog.dialog_text = "确定要编辑这个草稿吗？"
	
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
#	直接获取勾选的ID
	var delete_ids = _get_checked_draft_ids() 
	if delete_ids.is_empty():
		return

	# 创建确认对话框
	var dialog = ConfirmationDialog.new()
	dialog.title = "确认批量删除"
	dialog.dialog_text = "确定要删除选中的 %d 个草稿吗？此操作不可恢复！" % multi_selected_ids.size()

	# 确认回调
	dialog.confirmed.connect(
		func():
			var success_count = 0
			for id in delete_ids:
				if draft_service.delete_draft(id):
					success_count += 1

			# 显示操作结果
			if success_count > 0:
				load_drafts()	# 刷新列表
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
