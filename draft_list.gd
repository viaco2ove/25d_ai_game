extends Panel

signal draft_selected(draft_id: int)

var database: Node
var current_user_id: int = -1

func _ready():
	database = get_tree().root.get_node("MainNote/Database")
	$VBoxContainer/BackBtn.pressed.connect(_on_back_pressed)

# 设置当前用户ID并加载草稿
func set_user_id(user_id: int):
	current_user_id = user_id
	load_drafts()

# 加载用户草稿
func load_drafts():
	if current_user_id == -1:
		return

	var drafts = database.get_user_drafts(current_user_id)
	$VBoxContainer/DraftList.clear()

	for draft in drafts:
		var text = draft["title"] + " - " + draft["created_at"]
		$VBoxContainer/DraftList.add_item(text)
		# 将草稿ID存储在metadata中
		var index = $VBoxContainer/DraftList.get_item_count() - 1
		$VBoxContainer/DraftList.set_item_metadata(index, draft["id"])

	$VBoxContainer/DraftList.item_selected.connect(_on_draft_selected)

# 草稿项被选中
func _on_draft_selected(index: int):
	var draft_id = $VBoxContainer/DraftList.get_item_metadata(index)
	draft_selected.emit(draft_id)

# 返回按钮
func _on_back_pressed():
	queue_free()
