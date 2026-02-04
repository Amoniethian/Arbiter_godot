extends Node
## GameManager - Global game state management
## 游戏管理器 - 全局游戏状态管理

signal level_changed(level_id: String)
signal game_state_changed(new_state: GameState)
signal soul_killed(soul_id: String)
signal judgment_complete(success: bool)

enum GameState {
	TITLE,
	STORY,
	LEVEL_INTRO,
	PLAYING,
	CHARACTER_DETAIL,
	WEIGHING,
	JUDGMENT,
	RESULT,
	ENDING
}

## Current game state / 当前游戏状态
var current_state: GameState = GameState.TITLE

## Current level ID / 当前关卡ID
var current_level_id: String = ""

## Current level index (0-4) / 当前关卡索引
var current_level_index: int = 0

## Character positions in grid (index 0-8) / 角色在格子中的位置
## Key: grid position, Value: character ID
var grid_positions: Dictionary = {}

## Dead characters / 已死亡角色
var dead_characters: Array[String] = []

## Current level data / 当前关卡数据
var current_level_data: Dictionary = {}

## Player has seen intro / 玩家已看过开场
var has_seen_intro: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


## Change game state / 改变游戏状态
func change_state(new_state: GameState) -> void:
	current_state = new_state
	game_state_changed.emit(new_state)


## Load a level / 加载关卡
func load_level(level_id: String) -> void:
	current_level_id = level_id
	current_level_data = DataManager.get_level_data(level_id)
	dead_characters.clear()
	_initialize_grid_positions()
	level_changed.emit(level_id)


## Initialize grid with characters / 初始化格子中的角色
func _initialize_grid_positions() -> void:
	grid_positions.clear()
	if current_level_data.has("characters"):
		var characters: Array = current_level_data["characters"]
		for i in range(min(9, characters.size())):
			grid_positions[i] = characters[i]["id"]


## Swap two characters in grid / 交换两个角色的位置
func swap_characters(pos1: int, pos2: int) -> void:
	if pos1 < 0 or pos1 > 8 or pos2 < 0 or pos2 > 8:
		return
	var temp = grid_positions.get(pos1, "")
	grid_positions[pos1] = grid_positions.get(pos2, "")
	grid_positions[pos2] = temp


## Move character to position / 移动角色到位置
func move_character_to(character_id: String, target_pos: int) -> void:
	# Find current position
	var current_pos: int = -1
	for pos in grid_positions:
		if grid_positions[pos] == character_id:
			current_pos = pos
			break

	if current_pos >= 0 and target_pos >= 0 and target_pos <= 8:
		swap_characters(current_pos, target_pos)


## Get character at grid position / 获取格子位置的角色
func get_character_at(pos: int) -> String:
	return grid_positions.get(pos, "")


## Get position of character / 获取角色的位置
func get_character_position(character_id: String) -> int:
	for pos in grid_positions:
		if grid_positions[pos] == character_id:
			return pos
	return -1


## Check if position is center (index 4) / 检查是否是中心位置
func is_center_position(pos: int) -> bool:
	return pos == 4


## Kill a character / 杀死一个角色
func kill_character(character_id: String) -> void:
	if character_id not in dead_characters:
		dead_characters.append(character_id)
		soul_killed.emit(character_id)


## Check if character is dead / 检查角色是否死亡
func is_character_dead(character_id: String) -> bool:
	return character_id in dead_characters


## Execute judgment for demon levels / 执行恶魔关卡的判定
func execute_demon_judgment() -> bool:
	var center_character = get_character_at(4)
	if center_character.is_empty():
		return false

	# Find if center character is target
	for char_data in current_level_data.get("characters", []):
		if char_data["id"] == center_character:
			return char_data.get("is_target", false)

	return false


## Execute judgment for soul level / 执行灵魂关卡的判定
func execute_soul_judgment() -> Dictionary:
	var result = {
		"success": true,
		"killed_good": [],
		"killed_evil": []
	}

	# Get adjacency pairs from level data
	var adjacency = DataManager.get_adjacency_rules()
	var kill_rules = DataManager.get_kill_rules()

	# Check each adjacent pair
	for pair in adjacency:
		var pos1: int = pair[0]
		var pos2: int = pair[1]
		var char1_id = get_character_at(pos1)
		var char2_id = get_character_at(pos2)

		if char1_id.is_empty() or char2_id.is_empty():
			continue

		var char1_alignment = _get_character_alignment(char1_id)
		var char2_alignment = _get_character_alignment(char2_id)

		# Check both directions
		_apply_kill_rule(char1_id, char1_alignment, char2_id, char2_alignment, kill_rules, result)
		_apply_kill_rule(char2_id, char2_alignment, char1_id, char1_alignment, kill_rules, result)

	# Kill all affected characters
	for char_id in result["killed_good"] + result["killed_evil"]:
		kill_character(char_id)

	# Success if no good souls were killed
	result["success"] = result["killed_good"].is_empty()

	return result


## Get character alignment / 获取角色阵营
func _get_character_alignment(character_id: String) -> String:
	# First check in current level data
	for char_data in current_level_data.get("characters", []):
		if char_data["id"] == character_id:
			return char_data.get("alignment", "")

	# Then check in soul data
	var soul_data = DataManager.get_soul_data(character_id)
	if soul_data:
		return soul_data.get("alignment", "")

	return ""


## Apply kill rule between two characters / 应用两个角色之间的击杀规则
func _apply_kill_rule(attacker_id: String, attacker_align: String, victim_id: String, victim_align: String, rules: Array, result: Dictionary) -> void:
	for rule in rules:
		if rule["attacker"] == attacker_align and rule["victim"] == victim_align:
			if rule["result"] == "kill":
				if victim_id not in result["killed_good"] and victim_id not in result["killed_evil"]:
					if "good" in victim_align:
						result["killed_good"].append(victim_id)
					else:
						result["killed_evil"].append(victim_id)
			break


## Advance to next level / 进入下一关
func advance_to_next_level() -> bool:
	current_level_index += 1
	var levels = DataManager.get_all_levels()

	if current_level_index < levels.size():
		load_level(levels[current_level_index]["id"])
		return true

	return false  # No more levels


## Restart current level / 重新开始当前关卡
func restart_level() -> void:
	dead_characters.clear()
	_initialize_grid_positions()


## Reset game / 重置游戏
func reset_game() -> void:
	current_state = GameState.TITLE
	current_level_id = ""
	current_level_index = 0
	grid_positions.clear()
	dead_characters.clear()
	current_level_data = {}
	has_seen_intro = false


## Start new game / 开始新游戏
func start_new_game() -> void:
	reset_game()
	var levels = DataManager.get_all_levels()
	if levels.size() > 0:
		load_level(levels[0]["id"])
