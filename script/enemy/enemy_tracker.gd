class_name EnemyTracker extends Enemy

## 追踪型敌人（基类）
## 跨越轨道追踪玩家，斜向移动接近玩家
## 作为追踪型敌人的父类

@export_group("Tracker")
@export var track_speed: float = 120.0 ## 追踪速度（Y轴移动）
@export var track_range: float = 600.0 ## 开始追踪的距离
@export var track_color: Color = Color(0.3, 2.0, 0.5, 1.0) ## 追踪时的颜色（绿色）

var is_tracking: bool = false
var target_y: float = 0.0
var original_modulate: Color
var track_tween: Tween

func _ready() -> void:
	super._ready()
	if visuals:
		original_modulate = visuals.modulate

func _physics_process(delta: float) -> void:
	if is_hit_frozen:
		return

	# 水平移动
	position.x -= speed * delta

	# 追踪逻辑
	_process_tracking(delta)

	# 屏幕外销毁计时
	_update_offscreen_timer(delta)

## 处理追踪逻辑
func _process_tracking(delta: float) -> void:
	var player = Global.player_ref
	if not player:
		return

	var distance_to_player = position.x - player.position.x

	# 检测是否在追踪范围内
	if distance_to_player > 0 and distance_to_player <= track_range:
		if not is_tracking:
			_start_tracking()

		# 计算目标Y位置（玩家所在轨道）
		target_y = player.position.y

		# 斜向移动接近玩家
		var y_diff = target_y - position.y
		if abs(y_diff) > 5.0:
			var move_dir = sign(y_diff)
			position.y += move_dir * track_speed * delta
	else:
		if is_tracking:
			_stop_tracking()

## 开始追踪
func _start_tracking() -> void:
	is_tracking = true

	# 视觉效果
	if visuals:
		if track_tween and track_tween.is_valid():
			track_tween.kill()

		track_tween = create_tween()
		track_tween.tween_property(visuals, "modulate", track_color, 0.2)

	# 生成追踪粒子
	_spawn_track_particles()

## 停止追踪
func _stop_tracking() -> void:
	is_tracking = false

	# 恢复颜色
	if visuals:
		if track_tween and track_tween.is_valid():
			track_tween.kill()

		track_tween = create_tween()
		track_tween.tween_property(visuals, "modulate", original_modulate, 0.3)

	# 清理追踪粒子
	var trail = get_node_or_null("TrackTrail")
	if trail:
		trail.queue_free()

## 生成追踪拖尾粒子
func _spawn_track_particles() -> void:
	# 检查是否已存在
	if get_node_or_null("TrackTrail"):
		return

	var particles = CPUParticles2D.new()
	particles.name = "TrackTrail"
	particles.emitting = true
	particles.one_shot = false
	particles.amount = 15
	particles.lifetime = 0.4

	# 粒子外观 - 绿色追踪拖尾
	particles.modulate = Color(0.3, 2.5, 0.8, 1.0)
	particles.scale_amount_min = 4.0
	particles.scale_amount_max = 8.0

	# 粒子由大到小消散
	var curve = Curve.new()
	curve.add_point(Vector2(0.0, 1.0))
	curve.add_point(Vector2(0.5, 0.5))
	curve.add_point(Vector2(1.0, 0.0))
	particles.scale_amount_curve = curve

	# 粒子运动 - 向后喷射
	particles.direction = Vector2(1, 0)
	particles.spread = 40.0
	particles.initial_velocity_min = 80.0
	particles.initial_velocity_max = 150.0
	particles.gravity = Vector2.ZERO
	particles.damping_min = 80.0
	particles.damping_max = 120.0

	add_child(particles)
	particles.position = Vector2(30, 0)

## 重写死亡函数，清理拖尾
func die() -> void:
	var trail = get_node_or_null("TrackTrail")
	if trail:
		trail.queue_free()

	super.die()
