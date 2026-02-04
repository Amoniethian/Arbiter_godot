extends Control
class_name GridCell
## GridCell - A single cell in the 3x3 grid
## 格子单元 - 3x3网格中的单个格子

signal cell_clicked(cell: GridCell)
signal drag_started(cell: GridCell)
signal drag_ended(cell: GridCell, target_cell: GridCell)

@onready var background: Panel = $Background
@onready var character_sprite: TextureRect = $CharacterSprite
@onready var death_overlay: ColorRect = $DeathOverlay
@onready var fire_effect: CPUParticles2D = $FireEffect
@onready var highlight_border: Panel = $HighlightBorder
@onready var click_area: Button = $ClickArea

## Cell properties / 格子属性
var grid_position: int = -1
var character_id: String = ""
var is_dead: bool = false
var is_center: bool = false

## Drag state / 拖拽状态
var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var original_position: Vector2 = Vector2.ZERO
var mouse_start_position: Vector2 = Vector2.ZERO
var is_potential_click: bool = false

## Drag threshold - if mouse moves less than this, it's a click / 拖拽阈值 - 鼠标移动小于此值视为点击
const DRAG_THRESHOLD: float = 10.0


func _ready() -> void:
	_setup_styles()
	_connect_signals()


## Setup visual styles / 设置视觉样式
func _setup_styles() -> void:
	# Background style
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.1, 0.1, 0.1, 0.8)
	bg_style.border_color = Color(0.3, 0, 0, 1)
	bg_style.set_border_width_all(2)
	bg_style.set_corner_radius_all(5)
	background.add_theme_stylebox_override("panel", bg_style)

	# Highlight border style
	var highlight_style = StyleBoxFlat.new()
	highlight_style.bg_color = Color(0, 0, 0, 0)
	highlight_style.border_color = Color(1, 0.5, 0, 1)
	highlight_style.set_border_width_all(4)
	highlight_style.set_corner_radius_all(5)
	highlight_border.add_theme_stylebox_override("panel", highlight_style)

	# Update center cell style
	_update_center_style()


## Update style for center cell / 更新中心格子样式
func _update_center_style() -> void:
	if is_center:
		var center_style = StyleBoxFlat.new()
		center_style.bg_color = Color(0.15, 0.05, 0.05, 0.9)
		center_style.border_color = Color(0.8, 0, 0, 1)
		center_style.set_border_width_all(3)
		center_style.set_corner_radius_all(5)
		background.add_theme_stylebox_override("panel", center_style)


## Connect signals / 连接信号
func _connect_signals() -> void:
	click_area.button_down.connect(_on_button_down)
	click_area.button_up.connect(_on_button_up)


## Setup cell with data / 使用数据设置格子
func setup(pos: int, char_id: String) -> void:
	grid_position = pos
	character_id = char_id
	is_center = (pos == 4)
	is_dead = GameManager.is_character_dead(char_id)

	_update_center_style()
	_load_character_image()
	_update_death_state()


## Load character image / 加载角色图片
func _load_character_image() -> void:
	if character_id.is_empty():
		character_sprite.texture = null
		return

	var image_path = DataManager.get_character_image(character_id)
	if ResourceLoader.exists(image_path):
		character_sprite.texture = load(image_path)
	else:
		# Create placeholder
		_create_placeholder_texture()


## Create placeholder texture / 创建占位符纹理
func _create_placeholder_texture() -> void:
	var img = Image.create(180, 260, false, Image.FORMAT_RGBA8)

	# Check if this is the target demon in cheat mode / 检查作弊模式下是否是目标恶魔
	var is_target = GameManager.cheat_mode and GameManager.is_target_demon(character_id)

	# Use bright yellow for target demon, normal dark for others / 目标恶魔用明黄色，其他用暗色
	var bg_color = Color(1.0, 0.9, 0.0, 1) if is_target else Color(0.3, 0.2, 0.2, 1)
	var silhouette_color = Color(0.8, 0.6, 0.0, 1) if is_target else Color(0.5, 0.4, 0.4, 1)

	img.fill(bg_color)

	# Draw simple silhouette
	for y in range(40, 100):
		for x in range(70, 110):
			var dist = Vector2(x - 90, y - 70).length()
			if dist < 30:
				img.set_pixel(x, y, silhouette_color)

	for y in range(100, 240):
		for x in range(50, 130):
			img.set_pixel(x, y, silhouette_color)

	var tex = ImageTexture.create_from_image(img)
	character_sprite.texture = tex


## Update death visual state / 更新死亡视觉状态
func _update_death_state() -> void:
	death_overlay.visible = is_dead
	if is_dead:
		character_sprite.modulate = Color(0.3, 0.3, 0.3, 1)
	else:
		character_sprite.modulate = Color(1, 1, 1, 1)


## Kill character with effect / 杀死角色并播放效果
func kill() -> void:
	if is_dead:
		return

	is_dead = true
	death_overlay.visible = true

	# Play death animation
	var tween = create_tween()
	tween.tween_property(character_sprite, "modulate", Color(0.3, 0.3, 0.3, 1), 0.5)

	# Fire effect
	fire_effect.visible = true
	fire_effect.emitting = true

	# Play scream
	AudioManager.play_scream()

	# Stop fire after delay
	await get_tree().create_timer(1.5).timeout
	fire_effect.emitting = false


## Show highlight / 显示高亮
func show_highlight(show: bool) -> void:
	highlight_border.visible = show


## Handle button down / 处理按下
func _on_button_down() -> void:
	if is_dead:
		return

	# Store starting state / 存储起始状态
	mouse_start_position = get_global_mouse_position()
	original_position = global_position
	drag_offset = mouse_start_position - global_position
	is_potential_click = true
	is_dragging = false


## Handle button up / 处理释放
func _on_button_up() -> void:
	if is_dead:
		return

	var mouse_end_position = get_global_mouse_position()
	var mouse_distance = mouse_start_position.distance_to(mouse_end_position)

	if is_dragging:
		# Was dragging - end drag / 正在拖拽 - 结束拖拽
		is_dragging = false
		z_index = 0
		var target = _find_cell_at_position(mouse_end_position)
		drag_ended.emit(self, target)
	elif is_potential_click and mouse_distance < DRAG_THRESHOLD:
		# Was a click (didn't move much) / 是点击（没有移动太多）
		cell_clicked.emit(self)

	is_potential_click = false


## Process for drag / 拖拽处理
func _process(_delta: float) -> void:
	if is_potential_click and not is_dragging:
		# Check if we should start dragging / 检查是否应该开始拖拽
		var mouse_distance = mouse_start_position.distance_to(get_global_mouse_position())
		if mouse_distance >= DRAG_THRESHOLD:
			# Start dragging / 开始拖拽
			is_dragging = true
			is_potential_click = false
			z_index = 100
			drag_started.emit(self)

	if is_dragging:
		global_position = get_global_mouse_position() - drag_offset


## Find cell at position / 查找位置处的格子
func _find_cell_at_position(pos: Vector2) -> GridCell:
	# This will be handled by parent
	var parent = get_parent()
	if parent and parent.has_method("get_cell_at_position"):
		return parent.get_cell_at_position(pos)
	return null


## Reset position / 重置位置
func reset_position() -> void:
	global_position = original_position


## Get center position / 获取中心位置
func get_center() -> Vector2:
	return global_position + size / 2
