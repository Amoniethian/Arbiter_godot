extends Control
## EndingScreen - Game ending display
## 结局画面 - 游戏结局显示

signal return_to_title

@onready var background: ColorRect = $Background
@onready var title_label: Label = $Title
@onready var message_label: Label = $Message
@onready var return_button: Button = $ReturnButton

## Ending type / 结局类型
var ending_type: String = "good"


func _ready() -> void:
	_setup_ui()
	_connect_signals()
	_animate_entrance()


## Setup from main scene / 从主场景设置
func setup(data: Dictionary) -> void:
	ending_type = data.get("ending_type", "good")
	_update_content()


## Setup UI styles / 设置UI样式
func _setup_ui() -> void:
	# Button style
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.1, 0.1, 0.9)
	style.border_color = Color(0.8, 0, 0, 1)
	style.set_border_width_all(2)
	style.set_corner_radius_all(5)

	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = Color(0.4, 0.1, 0.1, 0.9)
	hover_style.border_color = Color(1, 0.3, 0.3, 1)
	hover_style.set_border_width_all(2)
	hover_style.set_corner_radius_all(5)

	return_button.add_theme_stylebox_override("normal", style)
	return_button.add_theme_stylebox_override("hover", hover_style)
	return_button.add_theme_color_override("font_color", Color(1, 1, 1, 1))


## Connect signals / 连接信号
func _connect_signals() -> void:
	return_button.pressed.connect(_on_return_pressed)


## Update content based on ending type / 根据结局类型更新内容
func _update_content() -> void:
	match ending_type:
		"good":
			title_label.text = "SALVATION"
			title_label.add_theme_color_override("font_color", Color(0.8, 1, 0.8, 1))
			message_label.text = "You have proven yourself as a true Arbiter.\nYour daughter is free.\nThe souls of the innocent are safe.\n\nMay you find peace."
			background.color = Color(0.05, 0.1, 0.05, 1)
		"bad":
			title_label.text = "DAMNATION"
			title_label.add_theme_color_override("font_color", Color(1, 0.5, 0.5, 1))
			message_label.text = "You have failed.\nThe innocent perished in flames.\nYour daughter remains trapped in the abyss.\n\nPerhaps... you will try again."
			background.color = Color(0.1, 0.02, 0.02, 1)


## Animate entrance / 入场动画
func _animate_entrance() -> void:
	modulate.a = 0
	title_label.modulate.a = 0
	message_label.modulate.a = 0
	return_button.modulate.a = 0

	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 1.0)
	tween.tween_property(title_label, "modulate:a", 1.0, 1.0)
	tween.tween_property(message_label, "modulate:a", 1.0, 1.5)
	tween.tween_property(return_button, "modulate:a", 1.0, 0.5)


## Handle return button / 处理返回按钮
func _on_return_pressed() -> void:
	AudioManager.play_click()
	return_to_title.emit()
