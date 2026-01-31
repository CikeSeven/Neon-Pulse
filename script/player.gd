extends CharacterBody2D


@onready var neon_trail: CPUParticles2D = $NeonTrail
@onready var impact_burst: CPUParticles2D = $ImpactBurst  # [新增] 请确保节点路径正确

# --- 配置参数 ---
@export_group("Motion")
@export var speed_x: float = 500
@export var lane_change_duration: float = 0.30

@export_group("equipment")
@export var weapon_scene: PackedScene

# --- 内部变量 ---
var movement_tween: Tween
var is_changing_lane: bool = false   ## 是否正在换道中
var impact_has_triggered: bool = false ## 防止一次换道触发多次爆炸
var move_direction: int = 0          ## 记录移动方向 (1=下, -1=上)

func _ready() -> void:
	Global.player_ref = self

func _physics_process(delta: float) -> void:
	handle_input()      # 1. 处理输入
	apply_movement(delta) # 2. 应用移动
	
	check_impact()      # [新增] 检测是否“撞线”
	
	update_visuals()    # 3. 更新拖尾效果 

# 处理玩家按键
func handle_input() -> void:
	if Input.is_action_just_pressed("UP"):
		change_lane(-1)
	elif Input.is_action_just_pressed("DOWN"):
		change_lane(1)
	
	var dir_x := Input.get_axis("LEFT", "RIGHT")
	velocity.x = dir_x * speed_x

# 执行移动逻辑
func apply_movement(_delta: float) -> void:
	move_and_slide()
	position.x = clamp(position.x, Global.get_limit_left(), Global.get_limit_right())

# 更改当前车道索引
func change_lane(direction: int) -> void:
	var next_lane = Global.current_lane1 + direction
	if next_lane >= 0 and next_lane < Global.lane_y_positions.size():
		Global.current_lane1 = next_lane
		# 把 direction 传给 tween 函数，因为我们需要知道往哪边撞
		start_lane_tween(Global.lane_y_positions[Global.current_lane1], direction)

# [修改] 增加了 direction 参数
func start_lane_tween(target_y: float, direction: int) -> void:
	if movement_tween and movement_tween.is_valid():
		movement_tween.kill()
	
	# --- 1. 设置状态 ---
	is_changing_lane = true
	impact_has_triggered = false
	move_direction = direction
	
	# --- 2. 创建动画 ---
	movement_tween = create_tween()
	movement_tween.tween_property(self, "position:y", target_y, lane_change_duration) \
		.set_trans(Tween.TRANS_BACK) \
		.set_ease(Tween.EASE_OUT)
	
	# 动画结束回调：重置状态
	movement_tween.finished.connect(func(): is_changing_lane = false)

# [新增] 核心逻辑：检测是否“撞”到了轨道线
func check_impact() -> void:
	# 如果不在换道，或者已经炸过了，就不用检测
	if not is_changing_lane or impact_has_triggered:
		return
	
	var target_y = Global.lane_y_positions[Global.current_lane1]
	var crossed_line = false
	
	# 判断逻辑：因为 TRANS_BACK 会过冲，所以我们检测“越线”的那一帧
	if move_direction == 1: # 向下移动
		if position.y >= target_y: # 只要Y坐标超过了目标线
			crossed_line = true
	elif move_direction == -1: # 向上移动
		if position.y <= target_y:
			crossed_line = true
			
	if crossed_line:
		trigger_impact_visuals() # 砰！
		impact_has_triggered = true # 标记已触发

# [新增] 触发爆炸特效
func trigger_impact_visuals() -> void:
	# restart() 会强制重置 One Shot 粒子并立即播放
	impact_burst.restart()
	impact_burst.emitting = true

# 处理常规拖尾特效
func update_visuals() -> void:
	# 如果正在换道，强制关闭拖尾
	if is_changing_lane:
		if neon_trail.emitting:
			neon_trail.emitting = false
		return

	# --- 下面是只有在“非换道”状态下才会执行的逻辑 ---
	var target_y = Global.lane_y_positions[Global.current_lane1]
	var distance_to_lane = abs(position.y - target_y)
	
	# 只有当非常接近目标轨道 (误差 < 2.0) 时才开启
	if distance_to_lane < 2.0:
		if not neon_trail.emitting:
			neon_trail.emitting = true
	else:
		# 防止有什么意外情况导致不在轨道上却没标记 changing_lane
		if neon_trail.emitting:
			neon_trail.emitting = false


func _exit_tree() -> void:
	Global.player_ref = null
