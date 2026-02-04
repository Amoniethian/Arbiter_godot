extends Control
## ScaleUI - Animated scale weighing display
## 天秤UI - 动画天秤称量显示

signal weighing_complete(result: Dictionary)

@onready var dimmer: ColorRect = $Dimmer
@onready var scale_container: Control = $ScaleContainer
@onready var pillar: Panel = $ScaleContainer/Pillar
@onready var beam: Panel = $ScaleContainer/Beam
@onready var left_pan: Panel = $ScaleContainer/LeftPan
@onready var left_chain: Panel = $ScaleContainer/LeftChain
@onready var left_ball: Panel = $ScaleContainer/LeftBall
@onready var right_pan: Panel = $ScaleContainer/RightPan
@onready var right_chain: Panel = $ScaleContainer/RightChain
@onready var right_ball: Panel = $ScaleContainer/RightBall
@onready var label: Label = $ScaleContainer/Label
@onready var animation_timer: Timer = $AnimationTimer

## Weighing data / 称量数据
var good_weight: float = 0.0
var evil_weight: float = 0.0

## Animation state / 动画状态
var target_rotation: float = 0.0
var current_rotation: float = 0.0
var animation_speed: float = 2.0
var is_animating: bool = false

## Initial positions / 初始位置
var left_pan_base_y: float = 0.0
var right_pan_base_y: float = 0.0
var left_ball_base_y: float = 0.0
var right_ball_base_y: float = 0.0


func _ready() -> void:
	_setup_styles()
	_store_initial_positions()
	visible = false


## Setup visual styles / 设置视觉样式
func _setup_styles() -> void:
	# Pillar style
	var pillar_style = StyleBoxFlat.new()
	pillar_style.bg_color = Color(0.4, 0.35, 0.3, 1)
	pillar_style.border_color = Color(0.3, 0.25, 0.2, 1)
	pillar_style.set_border_width_all(2)
	pillar.add_theme_stylebox_override("panel", pillar_style)

	# Beam style
	var beam_style = StyleBoxFlat.new()
	beam_style.bg_color = Color(0.5, 0.45, 0.4, 1)
	beam_style.border_color = Color(0.3, 0.25, 0.2, 1)
	beam_style.set_border_width_all(2)
	beam.add_theme_stylebox_override("panel", beam_style)

	# Pan style
	var pan_style = StyleBoxFlat.new()
	pan_style.bg_color = Color(0.6, 0.55, 0.5, 1)
	pan_style.border_color = Color(0.4, 0.35, 0.3, 1)
	pan_style.set_border_width_all(2)
	pan_style.set_corner_radius_all(5)
	left_pan.add_theme_stylebox_override("panel", pan_style)
	right_pan.add_theme_stylebox_override("panel", pan_style.duplicate())

	# Chain style
	var chain_style = StyleBoxFlat.new()
	chain_style.bg_color = Color(0.5, 0.45, 0.4, 1)
	left_chain.add_theme_stylebox_override("panel", chain_style)
	right_chain.add_theme_stylebox_override("panel", chain_style.duplicate())

	# Left ball (white/good)
	var left_ball_style = StyleBoxFlat.new()
	left_ball_style.bg_color = Color(1, 1, 1, 1)
	left_ball_style.border_color = Color(0.8, 0.8, 0.8, 1)
	left_ball_style.set_border_width_all(2)
	left_ball_style.set_corner_radius_all(35)
	left_ball.add_theme_stylebox_override("panel", left_ball_style)

	# Right ball (black/evil)
	var right_ball_style = StyleBoxFlat.new()
	right_ball_style.bg_color = Color(0.1, 0.1, 0.1, 1)
	right_ball_style.border_color = Color(0.3, 0.3, 0.3, 1)
	right_ball_style.set_border_width_all(2)
	right_ball_style.set_corner_radius_all(35)
	right_ball.add_theme_stylebox_override("panel", right_ball_style)


## Store initial positions / 存储初始位置
func _store_initial_positions() -> void:
	left_pan_base_y = left_pan.position.y
	right_pan_base_y = right_pan.position.y
	left_ball_base_y = left_ball.position.y
	right_ball_base_y = right_ball.position.y


## Start weighing animation / 开始称量动画
func start_weighing(good: float, evil: float) -> void:
	good_weight = good
	evil_weight = evil
	visible = true

	# Calculate target rotation based on weights
	var diff = evil - good
	target_rotation = clamp(diff * 5, -15, 15)  # Max 15 degrees tilt

	current_rotation = 0
	beam.rotation_degrees = 0
	is_animating = true

	# Reset positions
	_update_pan_positions(0)

	label.text = "Weighing Souls..."

	# Start animation
	var tween = create_tween()
	tween.tween_property(self, "current_rotation", target_rotation, 2.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	tween.tween_callback(_on_animation_complete)


## Update pan positions based on rotation / 根据旋转更新托盘位置
func _update_pan_positions(rotation_deg: float) -> void:
	beam.rotation_degrees = rotation_deg

	# Calculate vertical offset based on rotation
	var offset = sin(deg_to_rad(rotation_deg)) * 100

	# Left side goes up when rotation is positive
	left_pan.position.y = left_pan_base_y - offset
	left_chain.position.y = left_chain.position.y  # Chain stretches
	left_ball.position.y = left_ball_base_y - offset

	# Right side goes down when rotation is positive
	right_pan.position.y = right_pan_base_y + offset
	right_ball.position.y = right_ball_base_y + offset


## Process for animation / 动画处理
func _process(_delta: float) -> void:
	if is_animating:
		_update_pan_positions(current_rotation)


## Animation complete callback / 动画完成回调
func _on_animation_complete() -> void:
	is_animating = false

	# Update label based on result
	if good_weight > evil_weight:
		label.text = "Good prevails!"
		label.add_theme_color_override("font_color", Color(0.8, 1, 0.8, 1))
	elif evil_weight > good_weight:
		label.text = "Evil dominates..."
		label.add_theme_color_override("font_color", Color(1, 0.5, 0.5, 1))
	else:
		label.text = "Balance achieved"
		label.add_theme_color_override("font_color", Color(1, 1, 0.8, 1))

	# Wait then emit signal
	await get_tree().create_timer(2.0).timeout

	var result = {
		"good_weight": good_weight,
		"evil_weight": evil_weight,
		"success": good_weight >= evil_weight
	}
	weighing_complete.emit(result)


## Hide scale / 隐藏天秤
func hide_scale() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func(): visible = false; modulate.a = 1.0)
