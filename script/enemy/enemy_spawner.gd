extends Node2D

# 敌人池：可以在编辑器里拖拽多种敌人场景进来
@export var enemy_scenes: Array[PackedScene] 

@onready var spawn_timer: Timer = $SpawnTimer

func _ready() -> void:
	spawn_timer.timeout.connect(_spawn_enemy)

func _spawn_enemy() -> void:
	if enemy_scenes.is_empty():
		return
	
	# 随机选一个敌人种类
	var random_enemy_scene = enemy_scenes.pick_random()
	var enemy = random_enemy_scene.instantiate()
	
	# 随机选一条跑道
	var random_lane_y = Global.lane_y_positions.pick_random()
	
	# 设置生成位置

	var spawn_pos = Vector2(1080, random_lane_y)
	enemy.position = spawn_pos
	
	# 添加到场景
	# 注意：不要加到 Spawner 节点下，否则如果 Spawner 移动，敌人也会跟着移
	# 也不要直接 add_child，最好加到 World 根节点下
	get_tree().current_scene.add_child(enemy)
