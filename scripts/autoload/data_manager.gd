extends Node
## DataManager - Loads and manages all game data from JSON files
## 数据管理器 - 从JSON文件加载和管理所有游戏数据

## Loaded data cache / 加载的数据缓存
var _game_config: Dictionary = {}
var _levels_data: Dictionary = {}
var _characters_data: Dictionary = {}
var _dialogues_data: Dictionary = {}
var _story_data: Dictionary = {}

## Data file paths / 数据文件路径
const CONFIG_PATH = "res://data/game_config.json"
const LEVELS_PATH = "res://data/levels.json"
const CHARACTERS_PATH = "res://data/characters.json"
const DIALOGUES_PATH = "res://data/dialogues.json"
const STORY_PATH = "res://data/story.json"


func _ready() -> void:
	_load_all_data()


## Load all JSON data files / 加载所有JSON数据文件
func _load_all_data() -> void:
	_game_config = _load_json(CONFIG_PATH)
	_levels_data = _load_json(LEVELS_PATH)
	_characters_data = _load_json(CHARACTERS_PATH)
	_dialogues_data = _load_json(DIALOGUES_PATH)
	_story_data = _load_json(STORY_PATH)

	print("DataManager: All data loaded successfully")


## Load a single JSON file / 加载单个JSON文件
func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("DataManager: File not found: " + path)
		return {}

	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("DataManager: Cannot open file: " + path)
		return {}

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var error = json.parse(json_string)
	if error != OK:
		push_error("DataManager: JSON parse error in " + path + ": " + json.get_error_message())
		return {}

	return json.data


## Reload all data (useful for development) / 重新加载所有数据
func reload_data() -> void:
	_load_all_data()


# ============== Game Config ==============

## Get game settings / 获取游戏设置
func get_game_settings() -> Dictionary:
	return _game_config.get("game_settings", {})


## Get UI settings / 获取UI设置
func get_ui_settings() -> Dictionary:
	return _game_config.get("ui_settings", {})


## Get color settings / 获取颜色设置
func get_colors() -> Dictionary:
	return _game_config.get("colors", {})


## Get audio volume settings / 获取音量设置
func get_audio_volumes() -> Dictionary:
	return _game_config.get("audio_volumes", {})


## Get typewriter speed / 获取打字机速度
func get_typewriter_speed() -> float:
	return get_game_settings().get("typewriter_speed", 0.05)


# ============== Levels ==============

## Get all levels / 获取所有关卡
func get_all_levels() -> Array:
	return _levels_data.get("levels", [])


## Get level data by ID / 根据ID获取关卡数据
func get_level_data(level_id: String) -> Dictionary:
	for level in get_all_levels():
		if level.get("id", "") == level_id:
			return level
	return {}


## Get adjacency rules / 获取相邻规则
func get_adjacency_rules() -> Array:
	return _levels_data.get("adjacency_rules", {}).get("adjacent_pairs", [])


## Get kill rules / 获取击杀规则
func get_kill_rules() -> Array:
	return _levels_data.get("kill_rules", {}).get("rules", [])


# ============== Characters ==============

## Get questions list / 获取问题列表
func get_questions() -> Array:
	return _characters_data.get("questions", [])


## Get all demons data / 获取所有恶魔数据
func get_all_demons() -> Dictionary:
	return _characters_data.get("demons", {})


## Get demon data by ID / 根据ID获取恶魔数据
func get_demon_data(demon_id: String) -> Dictionary:
	return get_all_demons().get(demon_id, {})


## Get all souls data / 获取所有灵魂数据
func get_all_souls() -> Dictionary:
	return _characters_data.get("souls", {})


## Get soul data by ID / 根据ID获取灵魂数据
func get_soul_data(soul_id: String) -> Dictionary:
	return get_all_souls().get(soul_id, {})


## Check if character is a demon / 检查角色是否是恶魔
func is_demon(character_id: String) -> bool:
	return character_id.begins_with("S") and "-" in character_id and not character_id.begins_with("Soul")


## Check if character is a soul / 检查角色是否是灵魂
func is_soul(character_id: String) -> bool:
	return character_id.begins_with("Soul")


## Get character data (works for both demons and souls) / 获取角色数据
func get_character_data(character_id: String) -> Dictionary:
	# Try souls first
	var soul_data = get_soul_data(character_id)
	if not soul_data.is_empty():
		return soul_data

	# Try demons
	var demon_data = get_demon_data(character_id)
	if not demon_data.is_empty():
		return demon_data

	return {}


## Get demon dialogue lines / 获取恶魔对话行
func get_demon_dialogue(character_id: String) -> Array:
	var char_data = get_character_data(character_id)
	return char_data.get("dialogue", [])


## Get character image path / 获取角色图片路径
func get_character_image(character_id: String) -> String:
	var char_data = get_character_data(character_id)
	return char_data.get("image", "res://assets/images/characters/placeholder.png")


## Get character portrait path / 获取角色肖像路径
func get_character_portrait(character_id: String) -> String:
	var char_data = get_character_data(character_id)
	return char_data.get("portrait", "res://assets/images/characters/placeholder_portrait.png")


## Get character answer for question / 获取角色对问题的回答
func get_character_answer(character_id: String, question_id: String) -> Array:
	var char_data = get_character_data(character_id)
	var answers = char_data.get("answers", {})
	return answers.get(question_id, ["..."])


## Get character items / 获取角色物品
func get_character_items(character_id: String) -> Array:
	var char_data = get_character_data(character_id)
	return char_data.get("items", [])


# ============== Dialogues ==============

## Get Lucifer dialogue / 获取路西法对话
func get_lucifer_dialogue(dialogue_id: String) -> Dictionary:
	return _dialogues_data.get("lucifer_dialogues", {}).get(dialogue_id, {})


## Get eye tracker intro dialogue / 获取眼睛追踪器介绍对话
func get_eye_tracker_dialogue() -> Dictionary:
	return _dialogues_data.get("eye_tracker_intro", {})


# ============== Story ==============

## Get intro story segments / 获取开场故事片段
func get_intro_story() -> Array:
	return _story_data.get("intro_story", {}).get("segments", [])


## Get good ending story / 获取好结局故事
func get_good_ending() -> Array:
	return _story_data.get("ending_story", {}).get("good_ending", {}).get("segments", [])


## Get bad ending story / 获取坏结局故事
func get_bad_ending() -> Array:
	return _story_data.get("ending_story", {}).get("bad_ending", {}).get("segments", [])


# ============== Utility ==============

## Get localized text / 获取本地化文本
func get_localized_text(data: Dictionary, key: String, language: String = "en") -> String:
	var localized_key = key + "_" + language if language != "en" else key
	if data.has(localized_key):
		return data[localized_key]
	return data.get(key, "")
