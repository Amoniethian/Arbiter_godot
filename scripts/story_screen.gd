extends Control
## StoryScreen - Displays story segments with typewriter effect
## 故事画面 - 带打字机效果显示故事片段

signal story_finished(story_type: String)

@onready var background: TextureRect = $Background
@onready var background_color: ColorRect = $BackgroundColor
@onready var story_text: RichTextLabel = $TextContainer/StoryText
@onready var skip_button: Button = $SkipButton
@onready var continue_hint: Label = $ContinueHint
@onready var typewriter_timer: Timer = $TypewriterTimer
@onready var text_container: PanelContainer = $TextContainer

## Story data / 故事数据
var story_type: String = "intro"
var story_segments: Array = []
var current_segment_index: int = 0

## Typewriter state / 打字机状态
var current_full_text: String = ""
var current_display_index: int = 0
var is_typing: bool = false
var can_continue: bool = false


func _ready() -> void:
	_setup_ui()
	_connect_signals()


## Setup from main scene / 从主场景设置
func setup(data: Dictionary) -> void:
	story_type = data.get("story_type", "intro")
	_load_story_data()
	_show_segment(0)


## Setup UI styling / 设置UI样式
func _setup_ui() -> void:
	continue_hint.visible = false

	# Style skip button
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.1, 0.1, 0.7)
	style.border_color = Color(0.5, 0.2, 0.2, 1)
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	skip_button.add_theme_stylebox_override("normal", style)

	# Style text container
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0, 0, 0, 0.8)
	panel_style.border_color = Color(0.3, 0, 0, 1)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(5)
	panel_style.content_margin_left = 30
	panel_style.content_margin_right = 30
	panel_style.content_margin_top = 20
	panel_style.content_margin_bottom = 20
	text_container.add_theme_stylebox_override("panel", panel_style)


## Connect signals / 连接信号
func _connect_signals() -> void:
	skip_button.pressed.connect(_on_skip_pressed)
	typewriter_timer.timeout.connect(_on_typewriter_tick)


## Load story data from DataManager / 从DataManager加载故事数据
func _load_story_data() -> void:
	match story_type:
		"intro":
			story_segments = DataManager.get_intro_story()
		"good_ending":
			story_segments = DataManager.get_good_ending()
		"bad_ending":
			story_segments = DataManager.get_bad_ending()
		_:
			story_segments = []


## Show a story segment / 显示故事片段
func _show_segment(index: int) -> void:
	if index >= story_segments.size():
		_finish_story()
		return

	current_segment_index = index
	var segment = story_segments[index]

	# Load background
	_load_background(segment.get("background", ""))

	# Play voice if available
	var voice_path = segment.get("voice", "")
	if not voice_path.is_empty():
		AudioManager.play_voice(voice_path)

	# Start typewriter for text
	current_full_text = segment.get("text", "")
	_start_typewriter()


## Load background image / 加载背景图片
func _load_background(path: String) -> void:
	if path.is_empty() or not ResourceLoader.exists(path):
		background.texture = null
		background_color.visible = true
	else:
		background.texture = load(path)
		background_color.visible = false


## Start typewriter effect / 开始打字机效果
func _start_typewriter() -> void:
	current_display_index = 0
	is_typing = true
	can_continue = false
	continue_hint.visible = false
	story_text.text = ""

	typewriter_timer.wait_time = DataManager.get_typewriter_speed()
	typewriter_timer.start()
	AudioManager.play_typewriter()


## Typewriter timer tick / 打字机计时器触发
func _on_typewriter_tick() -> void:
	if current_display_index < current_full_text.length():
		current_display_index += 1
		story_text.text = current_full_text.substr(0, current_display_index)

		# Play typewriter sound occasionally
		if current_display_index % 3 == 0:
			AudioManager.play_typewriter()
	else:
		_finish_typewriter()


## Finish typewriter effect / 结束打字机效果
func _finish_typewriter() -> void:
	typewriter_timer.stop()
	AudioManager.stop_typewriter()
	story_text.text = current_full_text
	is_typing = false
	can_continue = true
	continue_hint.visible = true
	_animate_continue_hint()


## Skip to full text / 跳过到完整文本
func _skip_typewriter() -> void:
	typewriter_timer.stop()
	AudioManager.stop_typewriter()
	story_text.text = current_full_text
	is_typing = false
	can_continue = true
	continue_hint.visible = true


## Animate continue hint / 继续提示动画
func _animate_continue_hint() -> void:
	var tween = create_tween().set_loops()
	tween.tween_property(continue_hint, "modulate:a", 0.3, 0.8)
	tween.tween_property(continue_hint, "modulate:a", 1.0, 0.8)


## Handle skip button / 处理跳过按钮
func _on_skip_pressed() -> void:
	AudioManager.play_click()
	AudioManager.stop_voice()
	_finish_story()


## Handle input / 处理输入
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_handle_click()
	elif event is InputEventKey:
		if event.pressed and event.keycode == KEY_SPACE:
			_handle_click()


## Handle click / 处理点击
func _handle_click() -> void:
	if is_typing:
		# Skip to full text
		_skip_typewriter()
	elif can_continue:
		# Go to next segment
		AudioManager.stop_voice()
		_show_segment(current_segment_index + 1)


## Finish story and emit signal / 结束故事并发出信号
func _finish_story() -> void:
	AudioManager.stop_voice()
	story_finished.emit(story_type)
