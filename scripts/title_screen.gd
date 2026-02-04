extends Control
## TitleScreen - Main menu
## 标题画面 - 主菜单

signal start_game
signal quit_game

@onready var background: TextureRect = $Background
@onready var start_button: Button = $VBox/StartButton
@onready var quit_button: Button = $VBox/QuitButton
@onready var title_label: Label = $VBox/Title


func _ready() -> void:
	_setup_ui()
	_connect_signals()
	_load_background()
	_animate_title()


## Setup UI / 设置UI
func _setup_ui() -> void:
	# Apply button styles
	_style_button(start_button)
	_style_button(quit_button)


## Style a button / 设置按钮样式
func _style_button(button: Button) -> void:
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.2, 0.1, 0.1, 0.9)
	style_normal.border_color = Color(0.8, 0, 0, 1)
	style_normal.set_border_width_all(2)
	style_normal.set_corner_radius_all(5)

	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = Color(0.4, 0.1, 0.1, 0.9)
	style_hover.border_color = Color(1, 0.3, 0.3, 1)
	style_hover.set_border_width_all(2)
	style_hover.set_corner_radius_all(5)

	var style_pressed = StyleBoxFlat.new()
	style_pressed.bg_color = Color(0.1, 0.05, 0.05, 0.9)
	style_pressed.border_color = Color(0.6, 0, 0, 1)
	style_pressed.set_border_width_all(2)
	style_pressed.set_corner_radius_all(5)

	button.add_theme_stylebox_override("normal", style_normal)
	button.add_theme_stylebox_override("hover", style_hover)
	button.add_theme_stylebox_override("pressed", style_pressed)


## Connect button signals / 连接按钮信号
func _connect_signals() -> void:
	start_button.pressed.connect(_on_start_pressed)
	quit_button.pressed.connect(_on_quit_pressed)


## Load background image / 加载背景图片
func _load_background() -> void:
	var bg_path = "res://assets/images/backgrounds/title_bg.png"
	if ResourceLoader.exists(bg_path):
		background.texture = load(bg_path)
		$BackgroundColor.visible = false
	else:
		# Use color background as fallback
		$BackgroundColor.visible = true


## Animate title / 标题动画
func _animate_title() -> void:
	title_label.modulate.a = 0
	var tween = create_tween()
	tween.tween_property(title_label, "modulate:a", 1.0, 1.5)

	# Subtle pulsing effect
	var pulse_tween = create_tween().set_loops()
	pulse_tween.tween_property(title_label, "modulate", Color(1.2, 0.9, 0.9, 1), 2.0)
	pulse_tween.tween_property(title_label, "modulate", Color(1, 1, 1, 1), 2.0)


## Handle start button pressed / 处理开始按钮点击
func _on_start_pressed() -> void:
	AudioManager.play_click()
	start_game.emit()


## Handle quit button pressed / 处理退出按钮点击
func _on_quit_pressed() -> void:
	AudioManager.play_click()
	quit_game.emit()
