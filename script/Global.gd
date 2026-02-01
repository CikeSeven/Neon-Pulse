extends Node

# --- 信号 ---
signal player_hp_changed(current_hp: float, max_hp: float)
signal player_died()
signal screen_shake_requested(intensity: float, duration: float)

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
var current_level: int = 1
var gold: int = 0
var experience: int = 0

func get_limit_left() -> float:
	return -(screen_width * 0.45)


func get_limit_right() -> float:
	return 0

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
