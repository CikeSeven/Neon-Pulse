extends Node


var player_ref: CharacterBody2D = null

# 跑道坐标
var lane_y_positions: Array[float] =  [-200, 0, 200]
var current_lane1: int = 1 # 默认在中路

# 屏幕
var screen_width: float = 1920
var screen_height: float = 1080

# --- 动态游戏数据 ---
var score: int = 0
var current_level: int = 1

func get_limit_left() -> float:
	return -(screen_width * 0.45)


func get_limit_right() -> float:
	return 0
