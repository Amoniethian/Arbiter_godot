extends Control
## DialogBox - Dialog system with typewriter effect and eye tracker
## 对话框 - 带打字机效果和眼睛追踪器的对话系统

signal dialog_finished

@onready var dimmer: ColorRect = $Dimmer
@onready var dialog_panel: Panel = $DialogPanel
@onready var portrait: TextureRect = $DialogPanel/Portrait
@onready var speaker_label: Label = $DialogPanel/SpeakerLabel
@onready var dialog_text: RichTextLabel = $DialogPanel/DialogText
@onready var continue_hint: Label = $DialogPanel/ContinueHint
@onready var eye_container: Control = $EyeContainer
@onready var left_eye: Control = $EyeContainer/LeftEye
@onready var right_eye: Control = $EyeContainer/RightEye
@onready var left_pupil: Panel = $EyeContainer/LeftEye/Pupil
@onready var right_pupil: Panel = $EyeContainer/RightEye/Pupil
@onready var typewriter_timer: Timer = $TypewriterTimer

## Dialog data / 对话数据
var dialogue_data: Dictionary = {}
var dialogue_lines: Array = []
var current_line_index: int = 0

## Typewriter state / 打字机状态
var current_full_text: String = ""
var current_display_index: int = 0
var is_typing: bool = false
var can_continue: bool = false

## Eye tracker state / 眼睛追踪器状态
var show_eyes_after_dialog: bool = false
var eyes_visible: bool = false
var eye_max_offset: float = 20.0


func _ready() -> void:
	_setup_styles()
	_connect_signals()
	continue_hint.visible = false


## Setup visual styles / 设置视觉样式
func _setup_styles() -> void:
	# Dialog panel style
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.05, 0.05, 0.95)
	panel_style.border_color = Color(0.8, 0, 0, 1)
	panel_style.set_border_width_all(3)
	panel_style.set_corner_radius_all(10)
	dialog_panel.add_theme_stylebox_override("panel", panel_style)

	# Eye styles
	_setup_eye_styles()


## Setup eye styles / 设置眼睛样式
func _setup_eye_styles() -> void:
	# Eye white style
	var eye_white_style = StyleBoxFlat.new()
	eye_white_style.bg_color = Color(0.9, 0.85, 0.8, 1)
	eye_white_style.set_corner_radius_all(50)

	# Pupil style
	var pupil_style = StyleBoxFlat.new()
	pupil_style.bg_color = Color(0.1, 0, 0, 1)
	pupil_style.set_corner_radius_all(15)

	# Apply to left eye
	$EyeContainer/LeftEye/EyeWhite.add_theme_stylebox_override("panel", eye_white_style)
	left_pupil.add_theme_stylebox_override("panel", pupil_style)

	# Apply to right eye
	$EyeContainer/RightEye/EyeWhite.add_theme_stylebox_override("panel", eye_white_style.duplicate())
	right_pupil.add_theme_stylebox_override("panel", pupil_style.duplicate())


## Connect signals / 连接信号
func _connect_signals() -> void:
	typewriter_timer.timeout.connect(_on_typewriter_tick)


## Setup dialog with data / 使用数据设置对话
func setup(data: Dictionary) -> void:
	dialogue_data = data
	dialogue_lines = data.get("lines", [])
	current_line_index = 0
	show_eyes_after_dialog = data.get("show_eyes_after", false)
	eyes_visible = false
	eye_container.visible = false

	# Load portrait
	var portrait_path = data.get("portrait", "")
	if ResourceLoader.exists(portrait_path):
		portrait.texture = load(portrait_path)
	else:
		_create_portrait_placeholder()

	# Start first line
	if dialogue_lines.size() > 0:
		_show_line(0)


## Create portrait placeholder / 创建肖像占位符
func _create_portrait_placeholder() -> void:
	var img = Image.create(200, 350, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.15, 0.1, 0.1, 1))

	# Draw silhouette
	for y in range(30, 100):
		for x in range(60, 140):
			var dist = Vector2(x - 100, y - 65).length()
			if dist < 35:
				img.set_pixel(x, y, Color(0.25, 0.2, 0.2, 1))

	for y in range(100, 320):
		for x in range(40, 160):
			img.set_pixel(x, y, Color(0.25, 0.2, 0.2, 1))

	var tex = ImageTexture.create_from_image(img)
	portrait.texture = tex


## Show a dialogue line / 显示对话行
func _show_line(index: int) -> void:
	if index >= dialogue_lines.size():
		_on_all_lines_complete()
		return

	current_line_index = index
	var line_data = dialogue_lines[index]

	# Set speaker
	speaker_label.text = line_data.get("speaker", "???") + ":"

	# Start typewriter
	current_full_text = line_data.get("text", "")
	current_display_index = 0
	is_typing = true
	can_continue = false
	continue_hint.visible = false
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


## Finish typing / 完成打字
func _finish_typing() -> void:
	typewriter_timer.stop()
	dialog_text.text = current_full_text
	is_typing = false
	can_continue = true
	continue_hint.visible = true
	_animate_continue_hint()


## Skip typing / 跳过打字
func _skip_typing() -> void:
	typewriter_timer.stop()
	dialog_text.text = current_full_text
	is_typing = false
	can_continue = true
	continue_hint.visible = true


## Animate continue hint / 继续提示动画
func _animate_continue_hint() -> void:
	var tween = create_tween().set_loops()
	tween.tween_property(continue_hint, "modulate:a", 0.3, 0.6)
	tween.tween_property(continue_hint, "modulate:a", 1.0, 0.6)


## Called when all lines are complete / 所有行完成时调用
func _on_all_lines_complete() -> void:
	if show_eyes_after_dialog:
		_show_eyes()
	else:
		dialog_finished.emit()


## Show eyes / 显示眼睛
func _show_eyes() -> void:
	dialog_panel.visible = false
	eye_container.visible = true
	eyes_visible = true

	# Fade in eyes
	eye_container.modulate.a = 0
	var tween = create_tween()
	tween.tween_property(eye_container, "modulate:a", 1.0, 1.0)


## Process for eye tracking / 眼睛追踪处理
func _process(_delta: float) -> void:
	if not eyes_visible:
		return

	# Get mouse position relative to eye container center
	var mouse_pos = get_global_mouse_position()
	var container_center = eye_container.global_position + eye_container.size / 2

	var offset = (mouse_pos - container_center).normalized() * eye_max_offset

	# Clamp offset
	offset.x = clamp(offset.x, -eye_max_offset, eye_max_offset)
	offset.y = clamp(offset.y, -eye_max_offset, eye_max_offset)

	# Apply to pupils
	left_pupil.position = Vector2(left_eye.size.x / 2 - 15 + offset.x, left_eye.size.y / 2 - 15 + offset.y)
	right_pupil.position = Vector2(right_eye.size.x / 2 - 15 + offset.x, right_eye.size.y / 2 - 15 + offset.y)


## Handle input / 处理输入
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_handle_click()
	elif event is InputEventKey:
		if event.pressed and (event.keycode == KEY_SPACE or event.keycode == KEY_ENTER):
			_handle_click()


## Handle click / 处理点击
func _handle_click() -> void:
	if eyes_visible:
		# Close dialog when eyes are shown and clicked
		dialog_finished.emit()
		return

	if is_typing:
		_skip_typing()
	elif can_continue:
		_show_line(current_line_index + 1)


## Hide dialog / 隐藏对话
func hide_dialog() -> void:
	visible = false
	eyes_visible = false
	eye_container.visible = false
	dialog_panel.visible = true
