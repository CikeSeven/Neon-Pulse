extends CharacterBody2D


@onready var neon_trail: CPUParticles2D = $NeonTrail
@onready var impact_burst: CPUParticles2D = $ImpactBurst
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var visuals: ColorRect = $ColorRect

# --- 配置参数 ---
@export_group("Motion")
@export var speed_x: float = 500
@export var lane_change_duration: float = 0.30

@export_group("Combat")
@export var invincibility_duration: float = 1.0  ## 无敌帧持续时间

@export_group("equipment")
@export var weapon_scene: PackedScene

# --- 内部变量 ---
var movement_tween: Tween
var is_changing_lane: bool = false   ## 是否正在换道中
var impact_has_triggered: bool = false ## 防止一次换道触发多次爆炸
var move_direction: int = 0          ## 记录移动方向 (1=下, -1=上)

# --- 受击相关 ---
var is_invincible: bool = false      ## 是否处于无敌状态
var invincibility_tween: Tween       ## 无敌闪烁动画
var original_color: Color            ## 原始颜色


func _ready() -> void:
	Global.player_ref = self
	Global.reset_player_hp()

	# 保存原始颜色
	if visuals:
		original_color = visuals.color

	# 连接Hurtbox信号
	if hurtbox:
		hurtbox.hurt.connect(_on_hurtbox_hurt)

func _physics_process(delta: float) -> void:
	handle_input()      # 1. 处理输入
	apply_movement(delta) # 2. 应用移动

	check_impact()      # 检测是否"撞线"

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
		start_lane_tween(Global.lane_y_positions[Global.current_lane1], direction)

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

# 核心逻辑：检测是否"撞"到了轨道线
func check_impact() -> void:
	if not is_changing_lane or impact_has_triggered:
		return

	var target_y = Global.lane_y_positions[Global.current_lane1]
	var crossed_line = false

	if move_direction == 1: # 向下移动
		if position.y >= target_y:
			crossed_line = true
	elif move_direction == -1: # 向上移动
		if position.y <= target_y:
			crossed_line = true

	if crossed_line:
		trigger_impact_visuals()
		impact_has_triggered = true

# 触发爆炸特效
func trigger_impact_visuals() -> void:
	impact_burst.restart()
	impact_burst.emitting = true

# 处理常规拖尾特效
func update_visuals() -> void:
	if is_changing_lane:
		if neon_trail.emitting:
			neon_trail.emitting = false
		return

	var target_y = Global.lane_y_positions[Global.current_lane1]
	var distance_to_lane = abs(position.y - target_y)

	if distance_to_lane < 2.0:
		if not neon_trail.emitting:
			neon_trail.emitting = true
	else:
		if neon_trail.emitting:
			neon_trail.emitting = false

# ============================================================
# 受击系统
# ============================================================

## 受击回调函数
func _on_hurtbox_hurt(attacker_hitbox: Hitbox) -> void:
	if is_invincible:
		return

	var attacker = attacker_hitbox.owner

	# 普通敌人碰撞：玩家扣除敌人剩余血量，敌人死亡
	if attacker is Enemy:
		var enemy_hp = attacker.current_hp
		# 玩家扣除敌人剩余血量
		take_damage(enemy_hp)
		# 敌人也扣除同样的血量（即死亡）
		attacker.take_damage(enemy_hp)
	else:
		# 非敌人攻击（如飞行物），使用默认伤害
		var damage = attacker_hitbox.damage
		take_damage(damage)

## 受伤处理
func take_damage(amount: float) -> void:
	if is_invincible:
		return

	# 扣血
	Global.damage_player(amount)
	print("[PLAYER] Took %s damage. HP: %s/%s" % [amount, Global.player_current_hp, Global.player_max_hp])

	# 触发受击效果
	trigger_hit_effects()

	# 开启无敌帧
	start_invincibility()

	# 检查死亡
	if Global.player_current_hp <= 0:
		die()

## 触发受击视觉效果
func trigger_hit_effects() -> void:
	# 1. 角色闪白
	flash_hit()

	# 2. 屏幕震动
	Global.request_screen_shake(15.0, 0.25)

	# 3. 受击粒子效果
	spawn_hit_particles()

## 角色闪白效果
func flash_hit() -> void:
	if not visuals:
		return

	var tween = create_tween()
	# 闪白
	visuals.modulate = Color(10, 10, 10, 1)  # 超亮白色
	tween.tween_property(visuals, "modulate", Color.WHITE, 0.1)

## 生成受击粒子
func spawn_hit_particles() -> void:
	var hit_burst = CPUParticles2D.new()
	hit_burst.emitting = false
	hit_burst.one_shot = true
	hit_burst.explosiveness = 1.0
	hit_burst.amount = 15
	hit_burst.lifetime = 0.5

	# 粒子外观 - 红色霓虹
	hit_burst.modulate = Color(3.0, 0.3, 0.3, 1.0)
	hit_burst.scale_amount_min = 5.0
	hit_burst.scale_amount_max = 10.0

	# 粒子由大到小消散
	var curve = Curve.new()
	curve.add_point(Vector2(0.0, 1.0))  # 开始时满尺寸
	curve.add_point(Vector2(0.7, 0.5))  # 中间缩小
	curve.add_point(Vector2(1.0, 0.0))  # 结束时消失
	hit_burst.scale_amount_curve = curve

	# 粒子运动
	hit_burst.direction = Vector2.ZERO
	hit_burst.spread = 180.0
	hit_burst.initial_velocity_min = 100.0
	hit_burst.initial_velocity_max = 200.0
	hit_burst.gravity = Vector2.ZERO
	hit_burst.damping_min = 150.0
	hit_burst.damping_max = 250.0

	add_child(hit_burst)
	hit_burst.position = Vector2.ZERO
	hit_burst.restart()
	hit_burst.emitting = true

	# 自动清理
	get_tree().create_timer(1.0).timeout.connect(hit_burst.queue_free)

## 开启无敌帧
func start_invincibility() -> void:
	is_invincible = true

	# 停止之前的闪烁动画
	if invincibility_tween and invincibility_tween.is_valid():
		invincibility_tween.kill()

	# 创建闪烁动画
	invincibility_tween = create_tween()
	invincibility_tween.set_loops(int(invincibility_duration / 0.1))  # 循环次数

	# 闪烁效果：透明度变化
	invincibility_tween.tween_property(visuals, "modulate:a", 0.3, 0.05)
	invincibility_tween.tween_property(visuals, "modulate:a", 1.0, 0.05)

	# 无敌时间结束
	get_tree().create_timer(invincibility_duration).timeout.connect(end_invincibility)

## 结束无敌帧
func end_invincibility() -> void:
	is_invincible = false

	# 停止闪烁动画
	if invincibility_tween and invincibility_tween.is_valid():
		invincibility_tween.kill()

	# 恢复正常显示
	if visuals:
		visuals.modulate = Color.WHITE

## 死亡处理
func die() -> void:
	print("[PLAYER] DIED!")

	# 死亡特效
	spawn_death_particles()

	# 禁用输入
	set_physics_process(false)

	# 隐藏玩家
	if visuals:
		visuals.visible = false

	# 可以在这里触发游戏结束界面
	# get_tree().change_scene_to_file("res://scene/ui/game_over.tscn")

## 生成死亡粒子
func spawn_death_particles() -> void:
	# 大爆炸效果
	var death_burst = CPUParticles2D.new()
	death_burst.emitting = false
	death_burst.one_shot = true
	death_burst.explosiveness = 1.0
	death_burst.amount = 50
	death_burst.lifetime = 1.0

	# 粒子外观 - 亮红色霓虹
	death_burst.modulate = Color(5.0, 0.5, 0.5, 1.0)
	death_burst.scale_amount_min = 15.0
	death_burst.scale_amount_max = 25.0

	# 粒子由大到小消散
	var curve = Curve.new()
	curve.add_point(Vector2(0.0, 1.0))  # 开始时满尺寸
	curve.add_point(Vector2(0.4, 0.7))  # 快速缩小
	curve.add_point(Vector2(0.8, 0.3))  # 继续缩小
	curve.add_point(Vector2(1.0, 0.0))  # 结束时消失
	death_burst.scale_amount_curve = curve

	# 粒子运动 - 向外爆炸
	death_burst.direction = Vector2.ZERO
	death_burst.spread = 180.0
	death_burst.initial_velocity_min = 300.0
	death_burst.initial_velocity_max = 500.0
	death_burst.gravity = Vector2.ZERO
	death_burst.damping_min = 200.0
	death_burst.damping_max = 350.0

	# 添加到场景根节点（不随玩家销毁）
	get_tree().current_scene.add_child(death_burst)
	death_burst.global_position = global_position
	death_burst.restart()
	death_burst.emitting = true

	# 自动清理
	get_tree().create_timer(2.0).timeout.connect(death_burst.queue_free)


func _exit_tree() -> void:
	Global.player_ref = null
