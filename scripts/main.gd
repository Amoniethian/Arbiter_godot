extends Node
## Main - Scene management and transitions
## 主脚本 - 场景管理和过渡

@onready var scene_container: Control = $SceneContainer
@onready var transition_overlay: ColorRect = $TransitionOverlay

## Scene paths / 场景路径
const SCENES = {
	"title": "res://scenes/title_screen.tscn",
	"story": "res://scenes/story_screen.tscn",
	"level": "res://scenes/level.tscn",
	"character_detail": "res://scenes/character_detail.tscn",
	"ending": "res://scenes/ending_screen.tscn"
}

## Current scene instance / 当前场景实例
var current_scene: Node = null

## Transition duration / 过渡时长
var transition_duration: float = 0.5


func _ready() -> void:
	transition_overlay.modulate.a = 0
	transition_overlay.visible = true
	_load_title_screen()


## Load title screen / 加载标题画面
func _load_title_screen() -> void:
	change_scene("title")


## Change to a new scene / 切换到新场景
func change_scene(scene_key: String, data: Dictionary = {}) -> void:
	if not SCENES.has(scene_key):
		push_error("Main: Unknown scene key: " + scene_key)
		return

	# Fade out
	var tween = create_tween()
	tween.tween_property(transition_overlay, "modulate:a", 1.0, transition_duration)
	await tween.finished

	# Remove old scene
	if current_scene:
		current_scene.queue_free()
		current_scene = null

	# Load new scene
	var scene_path = SCENES[scene_key]
	var scene_resource = load(scene_path)
	if scene_resource:
		current_scene = scene_resource.instantiate()
		scene_container.add_child(current_scene)

		# Pass data to scene if it has a setup method
		if current_scene.has_method("setup"):
			current_scene.setup(data)

		# Connect scene signals
		_connect_scene_signals(current_scene, scene_key)

	# Fade in
	tween = create_tween()
	tween.tween_property(transition_overlay, "modulate:a", 0.0, transition_duration)


## Connect signals from scene / 连接场景信号
func _connect_scene_signals(scene: Node, scene_key: String) -> void:
	match scene_key:
		"title":
			if scene.has_signal("start_game"):
				scene.start_game.connect(_on_start_game)
			if scene.has_signal("quit_game"):
				scene.quit_game.connect(_on_quit_game)
		"story":
			if scene.has_signal("story_finished"):
				scene.story_finished.connect(_on_story_finished)
		"level":
			if scene.has_signal("level_complete"):
				scene.level_complete.connect(_on_level_complete)
			if scene.has_signal("show_character_detail"):
				scene.show_character_detail.connect(_on_show_character_detail)
			if scene.has_signal("return_to_title"):
				scene.return_to_title.connect(_on_return_to_title)
		"character_detail":
			if scene.has_signal("return_to_level"):
				scene.return_to_level.connect(_on_return_to_level)
		"ending":
			if scene.has_signal("return_to_title"):
				scene.return_to_title.connect(_on_return_to_title)


## Handle start game / 处理开始游戏
func _on_start_game() -> void:
	GameManager.change_state(GameManager.GameState.STORY)
	change_scene("story", {"story_type": "intro"})


## Handle quit game / 处理退出游戏
func _on_quit_game() -> void:
	get_tree().quit()


## Handle story finished / 处理故事结束
func _on_story_finished(story_type: String) -> void:
	match story_type:
		"intro":
			GameManager.start_new_game()
			GameManager.change_state(GameManager.GameState.LEVEL_INTRO)
			change_scene("level")
		"good_ending", "bad_ending":
			change_scene("title")


## Handle level complete / 处理关卡完成
func _on_level_complete(success: bool) -> void:
	if success:
		if GameManager.advance_to_next_level():
			# More levels to play
			change_scene("level")
		else:
			# Game complete - show good ending
			GameManager.change_state(GameManager.GameState.ENDING)
			change_scene("story", {"story_type": "good_ending"})
	else:
		# Show failure, allow retry
		pass  # Handled in level scene


## Handle show character detail / 处理显示角色详情
func _on_show_character_detail(character_id: String) -> void:
	GameManager.change_state(GameManager.GameState.CHARACTER_DETAIL)
	change_scene("character_detail", {"character_id": character_id})


## Handle return to level / 处理返回关卡
func _on_return_to_level() -> void:
	GameManager.change_state(GameManager.GameState.PLAYING)
	change_scene("level")


## Handle return to title / 处理返回标题
func _on_return_to_title() -> void:
	GameManager.reset_game()
	GameManager.change_state(GameManager.GameState.TITLE)
	change_scene("title")
