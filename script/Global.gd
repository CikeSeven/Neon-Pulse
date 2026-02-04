extends Node

# --- 信号 ---
signal player_hp_changed(current_hp: float, max_hp: float)
signal player_died()
signal screen_shake_requested(intensity: float, duration: float)
signal gold_changed(amount: int)
signal experience_changed(current_exp: int, exp_to_next: int, player_level: int)
signal player_leveled_up(new_level: int)

var player_ref: CharacterBody2D = null
var camera_ref: Camera2D = null

# 跑道坐标
var lane_y_positions: Array[float] =  [-200, 0, 200]
var current_lane1: int = 1 # 默认在中路

# 屏幕
var screen_width: float = 1920
var screen_height: float = 1080

# --- 玩家属性 ---
var player_max_hp: float = 100.0
var player_current_hp: float = 100.0

# --- 动态游戏数据 ---
var score: int = 0
var current_level: int = 1  ## 当前关卡
var gold: int = 0
var experience: int = 0  ## 当前经验（本级累计）
var player_level: int = 1  ## 玩家等级
var exp_range: float = 150.0  ## 经验吸引范围
var coin_range: float = 150.0 ## 金币吸引范围

var world_scroll_speed: float = 100.0 ## 世界滚动速度


func get_limit_left() -> float:
	return -(screen_width * 0.45)


func get_limit_right() -> float:
	return screen_width * 0.2

# --- 玩家生命值管理 ---
func damage_player(amount: float) -> void:
	player_current_hp = max(player_current_hp - amount, 0)
	player_hp_changed.emit(player_current_hp, player_max_hp)

	if player_current_hp <= 0:
		player_died.emit()

func heal_player(amount: float) -> void:
	player_current_hp = min(player_current_hp + amount, player_max_hp)
	player_hp_changed.emit(player_current_hp, player_max_hp)

func reset_player_hp() -> void:
	player_current_hp = player_max_hp
	player_hp_changed.emit(player_current_hp, player_max_hp)

# --- 屏幕震动请求 ---
func request_screen_shake(intensity: float = 10.0, duration: float = 0.3) -> void:
	screen_shake_requested.emit(intensity, duration)

# --- 金币管理 ---
func add_gold(amount: int) -> void:
	gold += amount
	gold_changed.emit(gold)

func spend_gold(amount: int) -> bool:
	if gold >= amount:
		gold -= amount
		gold_changed.emit(gold)
		return true
	return false

# --- 等级与经验管理 ---

## 计算指定等级升级所需经验
func get_exp_for_level(level: int) -> int:
	# 公式：100 × 等级^1.5
	return int(100.0 * pow(level, 1.5))

## 获取当前等级升级所需经验
func get_exp_to_next_level() -> int:
	return get_exp_for_level(player_level)

## 添加经验
func add_experience(amount: int) -> void:
	experience += amount

	# 检查是否升级
	var exp_needed = get_exp_to_next_level()
	while experience >= exp_needed:
		experience -= exp_needed
		player_level += 1
		player_leveled_up.emit(player_level)
		exp_needed = get_exp_to_next_level()

	experience_changed.emit(experience, get_exp_to_next_level(), player_level)

## 重置经验和等级
func reset_experience() -> void:
	experience = 0
	player_level = 1
	experience_changed.emit(experience, get_exp_to_next_level(), player_level)
