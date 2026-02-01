class_name Charger extends Enemy

## 冲撞型敌人
## 检测到玩家在同一轨道且在探测范围内时，启动后摇，后摇结束后高速冲撞

enum ChargerState {
	IDLE,       ## 正常移动
	WINDUP,     ## 后摇蓄力
	CHARGING,   ## 冲撞中
}

@export_group("Charger")
@export var detection_range: float = 800.0 ## 探测范围（向左）
@export var windup_duration: float = 0.8 ## 后摇时间
@export var charge_speed: float = 800.0 ## 冲撞速度
@export var charge_color: Color = Color(3.0, 1.5, 0.3, 1.0) ## 冲撞时的颜色（烈焰橙）

var state: ChargerState = ChargerState.IDLE
var windup_timer: float = 0.0
var windup_tween: Tween
var original_modulate: Color

func _ready() -> void:
	super._ready()
	if visuals:
		original_modulate = visuals.modulate

func _physics_process(delta: float) -> void:
	if is_hit_frozen:
		return

	match state:
		ChargerState.IDLE:
			_process_idle(delta)
		ChargerState.WINDUP:
			_process_windup(delta)
		ChargerState.CHARGING:
			_process_charging(delta)

## 正常移动状态
func _process_idle(delta: float) -> void:
	position.x -= speed * delta
	_check_player_in_range()

## 检测玩家是否在探测范围内
func _check_player_in_range() -> void:
	var player = Global.player_ref
	if not player:
		return

	# 检测是否在同一轨道
	var player_lane = Global.current_lane1
	var my_lane = _get_current_lane()

	if player_lane != my_lane:
		return

	# 检测玩家是否在探测范围内（玩家在敌人左边）
	var distance_to_player = position.x - player.position.x
	if distance_to_player > 0 and distance_to_player <= detection_range:
		_start_windup()

## 获取当前所在轨道
func _get_current_lane() -> int:
	var min_distance = INF
	var closest_lane = 0

	for i in range(Global.lane_y_positions.size()):
		var distance = abs(position.y - Global.lane_y_positions[i])
		if distance < min_distance:
			min_distance = distance
			closest_lane = i

	return closest_lane

## 开始后摇
func _start_windup() -> void:
	state = ChargerState.WINDUP
	windup_timer = windup_duration

	# 后摇视觉效果：闪烁警告
	_play_windup_effect()

## 后摇视觉效果
func _play_windup_effect() -> void:
	if not visuals:
		return

	# 停止之前的动画
	if windup_tween and windup_tween.is_valid():
		windup_tween.kill()

	# 创建闪烁动画
	windup_tween = create_tween()
	windup_tween.set_loops(int(windup_duration / 0.15))

	# 闪烁为橙色警告
	windup_tween.tween_property(visuals, "modulate", charge_color, 0.075)
	windup_tween.tween_property(visuals, "modulate", original_modulate, 0.075)

	# 生成蓄力粒子
	_spawn_windup_particles()

## 生成蓄力粒子
func _spawn_windup_particles() -> void:
	var particles = CPUParticles2D.new()
	particles.emitting = false
	particles.one_shot = false
	particles.amount = 8
	particles.lifetime = 0.3

	# 粒子外观 - 橙色能量聚集
	particles.modulate = Color(3.0, 1.5, 0.3, 1.0)
	particles.scale_amount_min = 3.0
	particles.scale_amount_max = 6.0

	# 粒子运动 - 向中心聚集
	particles.direction = Vector2(-1, 0)
	particles.spread = 60.0
	particles.initial_velocity_min = 50.0
	particles.initial_velocity_max = 100.0
	particles.gravity = Vector2.ZERO

	# 从外向内
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 40.0

	add_child(particles)
	particles.position = Vector2(-20, 0)
	particles.restart()
	particles.emitting = true

	# 后摇结束后清理
	get_tree().create_timer(windup_duration).timeout.connect(particles.queue_free)

## 后摇状态处理
func _process_windup(delta: float) -> void:
	# 后摇期间不移动
	windup_timer -= delta

	if windup_timer <= 0:
		_start_charge()

## 开始冲撞
func _start_charge() -> void:
	state = ChargerState.CHARGING

	# 停止闪烁动画
	if windup_tween and windup_tween.is_valid():
		windup_tween.kill()

	# 设置冲撞颜色
	if visuals:
		visuals.modulate = charge_color

	# 生成冲撞拖尾
	_spawn_charge_trail()

## 生成冲撞拖尾粒子
func _spawn_charge_trail() -> void:
	var particles = CPUParticles2D.new()
	particles.emitting = true
	particles.one_shot = false
	particles.amount = 20
	particles.lifetime = 0.4

	# 粒子外观 - 火焰拖尾
	particles.modulate = Color(3.0, 1.0, 0.2, 1.0)
	particles.scale_amount_min = 6.0
	particles.scale_amount_max = 12.0

	# 粒子运动 - 向后喷射
	particles.direction = Vector2(1, 0)
	particles.spread = 30.0
	particles.initial_velocity_min = 100.0
	particles.initial_velocity_max = 200.0
	particles.gravity = Vector2.ZERO
	particles.damping_min = 100.0
	particles.damping_max = 150.0

	add_child(particles)
	particles.position = Vector2(30, 0)
	particles.name = "ChargeTrail"

## 冲撞状态处理
func _process_charging(delta: float) -> void:
	# 高速向左冲撞
	position.x -= charge_speed * delta

## 冲撞时免疫击退
func apply_knockback(direction: Vector2, knockback_amount: float) -> void:
	if state == ChargerState.CHARGING:
		return
	super.apply_knockback(direction, knockback_amount)

## 重写死亡函数，清理拖尾
func die() -> void:
	# 清理冲撞拖尾
	var trail = get_node_or_null("ChargeTrail")
	if trail:
		trail.queue_free()

	super.die()
