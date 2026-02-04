extends Control
## CharacterDetail - Character detail page with questions and items
## 角色详情 - 带问题和物品的角色详情页面

signal return_to_level

@onready var left_panel: Panel = $LeftPanel
@onready var question_container: VBoxContainer = $LeftPanel/QuestionContainer
@onready var return_button: Button = $LeftPanel/ReturnButton
@onready var skeleton_decor: TextureRect = $LeftPanel/SkeletonDecor
@onready var center_panel: Panel = $CenterPanel
@onready var character_image: TextureRect = $CenterPanel/CharacterImage
@onready var right_panel: Panel = $RightPanel
@onready var item_grid: GridContainer = $RightPanel/ItemGrid
@onready var dialog_container: Control = $DialogContainer
@onready var dialog_bg: Panel = $DialogContainer/DialogBG
@onready var character_portrait: TextureRect = $DialogContainer/CharacterPortrait
@onready var speaker_name: Label = $DialogContainer/SpeakerName
@onready var dialog_text: RichTextLabel = $DialogContainer/DialogText
@onready var continue_indicator: Label = $DialogContainer/ContinueIndicator
@onready var typewriter_timer: Timer = $TypewriterTimer

## Character data / 角色数据
var character_id: String = ""
var character_data: Dictionary = {}

## Question buttons / 问题按钮
var question_buttons: Array[Button] = []

## Item slots / 物品槽
var item_slots: Array[Button] = []

## Dialog state / 对话状态
var current_dialogue: Array = []
var current_dialogue_index: int = 0
var current_full_text: String = ""
var current_display_index: int = 0
var is_typing: bool = false


func _ready() -> void:
	_setup_ui()
	_connect_signals()


## Setup from main scene / 从主场景设置
func setup(data: Dictionary) -> void:
	character_id = data.get("character_id", "")
	character_data = DataManager.get_character_data(character_id)
	_load_character()
	_create_question_buttons()
	_create_item_slots()


## Setup UI styles / 设置UI样式
func _setup_ui() -> void:
	# Style left panel (dark with skeleton decoration)
	var left_style = StyleBoxFlat.new()
	left_style.bg_color = Color(0, 0, 0, 1)
	left_panel.add_theme_stylebox_override("panel", left_style)

	# Style center panel
	var center_style = StyleBoxFlat.new()
	center_style.bg_color = Color(0.1, 0.1, 0.1, 1)
	center_panel.add_theme_stylebox_override("panel", center_style)

	# Style right panel
	var right_style = StyleBoxFlat.new()
	right_style.bg_color = Color(0.05, 0.05, 0.05, 1)
	right_panel.add_theme_stylebox_override("panel", right_style)

	# Style dialog background
	var dialog_style = StyleBoxFlat.new()
	dialog_style.bg_color = Color(1, 0.7, 0.75, 1)  # Light pink like reference
	dialog_style.border_color = Color(0.8, 0, 0, 1)
	dialog_style.set_border_width_all(0)
	dialog_style.set_corner_radius_all(0)
	dialog_bg.add_theme_stylebox_override("panel", dialog_style)

	# Style return button
	_style_button(return_button)

	# Hide dialog initially
	dialog_container.visible = false
	continue_indicator.visible = false


## Style a button / 设置按钮样式
func _style_button(button: Button) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.9, 0.9, 0.9, 1)
	style.border_color = Color(0.3, 0.3, 0.3, 1)
	style.set_border_width_all(2)
	style.set_corner_radius_all(5)

	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = Color(1, 1, 1, 1)
	hover_style.border_color = Color(0, 0, 0, 1)
	hover_style.set_border_width_all(2)
	hover_style.set_corner_radius_all(5)

	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_color_override("font_color", Color(0, 0, 0, 1))
	button.add_theme_color_override("font_hover_color", Color(0, 0, 0, 1))


## Connect signals / 连接信号
func _connect_signals() -> void:
	return_button.pressed.connect(_on_return_pressed)
	typewriter_timer.timeout.connect(_on_typewriter_tick)


## Load character data and image / 加载角色数据和图片
func _load_character() -> void:
	# Load character image
	var image_path = character_data.get("image", "")
	if ResourceLoader.exists(image_path):
		character_image.texture = load(image_path)
	else:
		_create_character_placeholder()

	# Load portrait for dialog
	var portrait_path = character_data.get("portrait", "")
	if ResourceLoader.exists(portrait_path):
		character_portrait.texture = load(portrait_path)

	# Load skeleton decoration
	var skeleton_path = "res://assets/images/ui/skeleton_decor.png"
	if ResourceLoader.exists(skeleton_path):
		skeleton_decor.texture = load(skeleton_path)


## Create character placeholder / 创建角色占位符
func _create_character_placeholder() -> void:
	var img = Image.create(360, 700, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.4, 0.3, 0.3, 1))

	# Draw silhouette
	for y in range(50, 150):
		for x in range(130, 230):
			var dist = Vector2(x - 180, y - 100).length()
			if dist < 50:
				img.set_pixel(x, y, Color(0.6, 0.5, 0.5, 1))

	for y in range(150, 650):
		for x in range(80, 280):
			img.set_pixel(x, y, Color(0.6, 0.5, 0.5, 1))

	var tex = ImageTexture.create_from_image(img)
	character_image.texture = tex


## Create question buttons / 创建问题按钮
func _create_question_buttons() -> void:
	# Clear existing buttons
	for btn in question_buttons:
		btn.queue_free()
	question_buttons.clear()

	# Get questions from data
	var questions = DataManager.get_questions()

	for question in questions:
		var btn = Button.new()
		btn.text = question.get("text", "???")
		btn.custom_minimum_size = Vector2(280, 60)
		_style_button(btn)

		var question_id = question.get("id", "")
		btn.pressed.connect(_on_question_pressed.bind(question_id))

		question_container.add_child(btn)
		question_buttons.append(btn)


## Create item slots / 创建物品槽
func _create_item_slots() -> void:
	# Clear existing slots
	for slot in item_slots:
		slot.queue_free()
	item_slots.clear()

	# Get items from character data
	var items = character_data.get("items", [])

	# Create 6 slots (3x2 grid)
	for i in range(6):
		var slot = Button.new()
		slot.custom_minimum_size = Vector2(150, 150)
		slot.flat = true

		var style = StyleBoxFlat.new()
		style.bg_color = Color(1, 1, 1, 1)
		style.border_color = Color(0.3, 0.3, 0.3, 1)
		style.set_border_width_all(2)
		slot.add_theme_stylebox_override("normal", style)

		if i < items.size():
			var item = items[i]
			# Load item icon
			var icon_path = item.get("icon", "")
			if ResourceLoader.exists(icon_path):
				var tex = load(icon_path)
				slot.icon = tex
			else:
				# Create placeholder icon
				slot.text = "Item"

			slot.pressed.connect(_on_item_pressed.bind(item))
		else:
			# Empty slot
			slot.disabled = true
			style.bg_color = Color(0.8, 0.8, 0.8, 1)

		item_grid.add_child(slot)
		item_slots.append(slot)


## Handle question button pressed / 处理问题按钮点击
func _on_question_pressed(question_id: String) -> void:
	AudioManager.play_click()

	# Get character's answer
	var answers = DataManager.get_character_answer(character_id, question_id)

	# Start dialogue
	_start_dialogue(answers)


## Handle item pressed / 处理物品点击
func _on_item_pressed(item: Dictionary) -> void:
	AudioManager.play_click()

	# Get item dialogue
	var dialogue = item.get("dialogue", ["..."])

	# Start dialogue
	_start_dialogue(dialogue)


## Start dialogue / 开始对话
func _start_dialogue(lines: Array) -> void:
	current_dialogue = lines
	current_dialogue_index = 0
	dialog_container.visible = true

	# Set speaker name
	var char_name = character_data.get("name", "Unknown")
	speaker_name.text = char_name + ":"

	# Start first line
	_show_dialogue_line(0)


## Show dialogue line / 显示对话行
func _show_dialogue_line(index: int) -> void:
	if index >= current_dialogue.size():
		_end_dialogue()
		return

	current_dialogue_index = index
	current_full_text = current_dialogue[index]
	current_display_index = 0
	is_typing = true
	continue_indicator.visible = false
	dialog_text.text = ""

	typewriter_timer.wait_time = DataManager.get_typewriter_speed()
	typewriter_timer.start()


## Typewriter timer tick / 打字机计时器触发
func _on_typewriter_tick() -> void:
	if current_display_index < current_full_text.length():
		current_display_index += 1
		dialog_text.text = current_full_text.substr(0, current_display_index)
	else:
		_finish_typing()


## Finish typing current line / 完成当前行打字
func _finish_typing() -> void:
	typewriter_timer.stop()
	dialog_text.text = current_full_text
	is_typing = false
	continue_indicator.visible = true
	_animate_continue_indicator()


## Skip to full text / 跳到完整文本
func _skip_typing() -> void:
	typewriter_timer.stop()
	dialog_text.text = current_full_text
	is_typing = false
	continue_indicator.visible = true


## Animate continue indicator / 继续指示器动画
func _animate_continue_indicator() -> void:
	var tween = create_tween().set_loops()
	tween.tween_property(continue_indicator, "modulate:a", 0.3, 0.5)
	tween.tween_property(continue_indicator, "modulate:a", 1.0, 0.5)


## End dialogue / 结束对话
func _end_dialogue() -> void:
	dialog_container.visible = false
	current_dialogue.clear()


## Handle input for dialogue / 处理对话输入
func _input(event: InputEvent) -> void:
	if not dialog_container.visible:
		return

	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_handle_dialogue_click()
	elif event is InputEventKey:
		if event.pressed and (event.keycode == KEY_SPACE or event.keycode == KEY_ENTER):
			_handle_dialogue_click()


## Handle dialogue click / 处理对话点击
func _handle_dialogue_click() -> void:
	if is_typing:
		_skip_typing()
	else:
		_show_dialogue_line(current_dialogue_index + 1)


## Handle return button / 处理返回按钮
func _on_return_pressed() -> void:
	AudioManager.play_click()
	return_to_level.emit()
