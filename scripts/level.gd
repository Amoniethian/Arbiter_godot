extends Control
## Level - Main gameplay level with 3x3 grid
## 关卡 - 带3x3网格的主要游戏关卡

signal level_complete(success: bool)
signal show_character_detail(character_id: String)
signal return_to_title

@onready var background: TextureRect = $Background
@onready var background_color: ColorRect = $BackgroundColor
@onready var lucifer_area: Panel = $LuciferArea
@onready var lucifer_image: TextureRect = $LuciferArea/LuciferImage
@onready var grid_container: Control = $GridContainer
@onready var weigh_button: Button = $RightPanel/WeighButton
@onready var return_button: Button = $RightPanel/ReturnButton
@onready var scale_icon: TextureRect = $RightPanel/ScaleIcon
@onready var good_indicator: Panel = $RightPanel/ScaleDisplay/GoodIndicator
@onready var evil_indicator: Panel = $RightPanel/ScaleDisplay/EvilIndicator
@onready var dialog_overlay: Control = $DialogOverlay
@onready var result_overlay: Control = $ResultOverlay
@onready var result_text: Label = $ResultOverlay/ResultText
@onready var continue_button: Button = $ResultOverlay/ContinueButton

## Grid cells / 网格单元
var grid_cells: Array[GridCell] = []
const GRID_CELL_SCENE = preload("res://scenes/ui/grid_cell.tscn")

## Grid configuration / 网格配置
var cell_size: Vector2 = Vector2(200, 280)
var cell_spacing: float = 20.0

## Drag state / 拖拽状态
var dragging_cell: GridCell = null

## Dialog system / 对话系统
var dialog_box: Control = null


func _ready() -> void:
	_setup_ui()
	_connect_signals()
	_create_grid()
	_load_level_data()
	_show_intro_dialog()


## Setup UI elements / 设置UI元素
func _setup_ui() -> void:
	# Style Lucifer area
	var lucifer_style = StyleBoxFlat.new()
	lucifer_style.bg_color = Color(0, 0, 0, 0.9)
	lucifer_area.add_theme_stylebox_override("panel", lucifer_style)

	# Style buttons
	_style_button(weigh_button, Color(0.8, 0, 0, 1))
	_style_button(return_button, Color(0.4, 0.4, 0.4, 1))
	_style_button(continue_button, Color(0.8, 0, 0, 1))

	# Style indicators
	_style_indicator(good_indicator, Color(1, 1, 1, 1))
	_style_indicator(evil_indicator, Color(0, 0, 0, 1))

	# Style scale placeholder
	var scale_style = StyleBoxFlat.new()
	scale_style.bg_color = Color(0.2, 0.2, 0.2, 1)
	scale_style.border_color = Color(0.5, 0.5, 0.5, 1)
	scale_style.set_border_width_all(2)
	$RightPanel/ScaleIcon/ScalePlaceholder.add_theme_stylebox_override("panel", scale_style)


## Style a button / 设置按钮样式
func _style_button(button: Button, color: Color) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = color.darkened(0.5)
	style.border_color = color
	style.set_border_width_all(2)
	style.set_corner_radius_all(5)

	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = color.darkened(0.3)
	hover_style.border_color = color.lightened(0.2)
	hover_style.set_border_width_all(2)
	hover_style.set_corner_radius_all(5)

	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", hover_style)


## Style an indicator / 设置指示器样式
func _style_indicator(panel: Panel, color: Color) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color(0.5, 0.5, 0.5, 1)
	style.set_border_width_all(2)
	style.set_corner_radius_all(25)  # Make it circular
	panel.add_theme_stylebox_override("panel", style)


## Connect signals / 连接信号
func _connect_signals() -> void:
	weigh_button.pressed.connect(_on_weigh_pressed)
	return_button.pressed.connect(_on_return_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	GameManager.soul_killed.connect(_on_soul_killed)


## Create 3x3 grid / 创建3x3网格
func _create_grid() -> void:
	# Clear existing cells
	for cell in grid_cells:
		cell.queue_free()
	grid_cells.clear()

	# Calculate grid dimensions
	var total_width = cell_size.x * 3 + cell_spacing * 2
	var total_height = cell_size.y * 3 + cell_spacing * 2
	var start_x = (grid_container.size.x - total_width) / 2
	var start_y = (grid_container.size.y - total_height) / 2

	# Create cells
	for i in range(9):
		var cell = GRID_CELL_SCENE.instantiate() as GridCell
		grid_container.add_child(cell)

		var row = i / 3
		var col = i % 3
		var pos_x = start_x + col * (cell_size.x + cell_spacing)
		var pos_y = start_y + row * (cell_size.y + cell_spacing)

		cell.position = Vector2(pos_x, pos_y)
		cell.size = cell_size

		# Connect cell signals
		cell.cell_clicked.connect(_on_cell_clicked)
		cell.drag_started.connect(_on_drag_started)
		cell.drag_ended.connect(_on_drag_ended)

		grid_cells.append(cell)


## Load level data / 加载关卡数据
func _load_level_data() -> void:
	var level_data = GameManager.current_level_data
	if level_data.is_empty():
		return

	# Load background
	var bg_path = level_data.get("background", "")
	if ResourceLoader.exists(bg_path):
		background.texture = load(bg_path)
		background_color.visible = false
	else:
		background_color.visible = true

	# Play BGM
	var bgm_path = level_data.get("bgm", "")
	if not bgm_path.is_empty():
		AudioManager.play_bgm(bgm_path)

	# Setup grid cells with characters
	_refresh_grid()

	# Load Lucifer image
	var lucifer_path = "res://assets/images/characters/lucifer.png"
	if ResourceLoader.exists(lucifer_path):
		lucifer_image.texture = load(lucifer_path)
	else:
		_create_lucifer_placeholder()


## Create Lucifer placeholder / 创建路西法占位符
func _create_lucifer_placeholder() -> void:
	var img = Image.create(380, 580, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.1, 0.1, 0.1, 1))

	# Draw silhouette
	for y in range(50, 150):
		for x in range(140, 240):
			var dist = Vector2(x - 190, y - 100).length()
			if dist < 50:
				img.set_pixel(x, y, Color(0.2, 0.15, 0.15, 1))

	for y in range(150, 550):
		for x in range(100, 280):
			img.set_pixel(x, y, Color(0.2, 0.15, 0.15, 1))

	var tex = ImageTexture.create_from_image(img)
	lucifer_image.texture = tex


## Refresh grid display / 刷新网格显示
func _refresh_grid() -> void:
	for i in range(9):
		var char_id = GameManager.get_character_at(i)
		grid_cells[i].setup(i, char_id)


## Show intro dialog / 显示介绍对话
func _show_intro_dialog() -> void:
	var level_data = GameManager.current_level_data
	var intro_id = level_data.get("intro_dialogue", "")
	if intro_id.is_empty():
		return

	# Load and show dialog
	_show_lucifer_dialog(intro_id)


## Show Lucifer dialog / 显示路西法对话
func _show_lucifer_dialog(dialogue_id: String) -> void:
	var dialogue_data = DataManager.get_lucifer_dialogue(dialogue_id)
	if dialogue_data.is_empty():
		return

	# Create dialog box if not exists
	if not dialog_box:
		_create_dialog_box()

	dialog_overlay.visible = true
	dialog_box.visible = true
	dialog_box.setup(dialogue_data)


## Create dialog box / 创建对话框
func _create_dialog_box() -> void:
	var dialog_scene = load("res://scenes/ui/dialog_box.tscn")
	if dialog_scene:
		dialog_box = dialog_scene.instantiate()
		dialog_overlay.add_child(dialog_box)
		dialog_box.dialog_finished.connect(_on_dialog_finished)


## Get cell at global position / 获取全局位置处的格子
func get_cell_at_position(pos: Vector2) -> GridCell:
	for cell in grid_cells:
		if cell == dragging_cell:
			continue
		var rect = Rect2(cell.global_position, cell.size)
		if rect.has_point(pos):
			return cell
	return null


## Handle cell clicked / 处理格子点击
func _on_cell_clicked(cell: GridCell) -> void:
	AudioManager.play_click()
	show_character_detail.emit(cell.character_id)


## Handle drag started / 处理拖拽开始
func _on_drag_started(cell: GridCell) -> void:
	dragging_cell = cell

	# Highlight valid drop targets
	for c in grid_cells:
		if c != cell and not c.is_dead:
			c.show_highlight(true)


## Handle drag ended / 处理拖拽结束
func _on_drag_ended(source_cell: GridCell, _target_cell: GridCell) -> void:
	# Hide highlights
	for c in grid_cells:
		c.show_highlight(false)

	# Find target cell at current mouse position (ignore passed target, it's always null)
	# 在当前鼠标位置查找目标格子（忽略传入的target，它总是null）
	var target_cell = get_cell_at_position(get_global_mouse_position())

	# Always reset visual position first / 先重置视觉位置
	source_cell.reset_position()

	if target_cell and target_cell != source_cell and not target_cell.is_dead:
		# Swap characters in GameManager / 在GameManager中交换角色
		GameManager.swap_characters(source_cell.grid_position, target_cell.grid_position)
		# Refresh grid to show swapped characters / 刷新网格显示交换后的角色
		_refresh_grid()
		# Play swap sound / 播放交换音效
		AudioManager.play_click()

	dragging_cell = null


## Handle weigh button pressed / 处理称量按钮点击
func _on_weigh_pressed() -> void:
	AudioManager.play_click()
	AudioManager.play_scale_weigh()

	var level_type = GameManager.current_level_data.get("type", "")

	if level_type == "demon":
		_execute_demon_judgment()
	else:
		_execute_soul_judgment()


## Execute demon level judgment / 执行恶魔关卡判定
func _execute_demon_judgment() -> void:
	var success = GameManager.execute_demon_judgment()
	_show_result(success)


## Execute soul level judgment / 执行灵魂关卡判定
func _execute_soul_judgment() -> void:
	var result = GameManager.execute_soul_judgment()

	# Animate deaths
	for char_id in result["killed_good"] + result["killed_evil"]:
		var pos = GameManager.get_character_position(char_id)
		if pos >= 0 and pos < grid_cells.size():
			await grid_cells[pos].kill()
			await get_tree().create_timer(0.3).timeout

	_show_result(result["success"])


## Show result / 显示结果
func _show_result(success: bool) -> void:
	result_overlay.visible = true

	if success:
		result_text.text = "SUCCESS"
		result_text.add_theme_color_override("font_color", Color(0.3, 1, 0.3, 1))

		# Show success dialog
		var success_id = GameManager.current_level_data.get("success_dialogue", "")
		if not success_id.is_empty():
			_show_lucifer_dialog(success_id)
	else:
		result_text.text = "FAILURE"
		result_text.add_theme_color_override("font_color", Color(1, 0.3, 0.3, 1))

		# Show failure dialog
		var failure_id = GameManager.current_level_data.get("failure_dialogue", "")
		if not failure_id.is_empty():
			_show_lucifer_dialog(failure_id)


## Handle soul killed / 处理灵魂被杀
func _on_soul_killed(soul_id: String) -> void:
	var pos = GameManager.get_character_position(soul_id)
	if pos >= 0 and pos < grid_cells.size():
		grid_cells[pos].kill()


## Handle return button pressed / 处理返回按钮点击
func _on_return_pressed() -> void:
	AudioManager.play_click()
	return_to_title.emit()


## Handle continue button pressed / 处理继续按钮点击
func _on_continue_pressed() -> void:
	AudioManager.play_click()
	result_overlay.visible = false

	var success = result_text.text == "SUCCESS"
	if success:
		level_complete.emit(true)
	else:
		# Allow retry
		GameManager.restart_level()
		_refresh_grid()


## Handle dialog finished / 处理对话结束
func _on_dialog_finished() -> void:
	dialog_overlay.visible = false
	if dialog_box:
		dialog_box.visible = false
