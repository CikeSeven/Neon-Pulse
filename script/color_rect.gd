extends ColorRect

## 玩家视觉效果控制
## 包含经验进度环显示

@onready var core_circle: Node2D = $CoreCircle
@onready var core_glow_particles: CPUParticles2D = $CoreCircle/CoreGlowParticles
@onready var orbit_particles: CPUParticles2D = $CoreCircle/OrbitParticles

var exp_progress_ring: Line2D
var exp_glow_ring: Line2D

## 进度环配置
const RING_RADIUS: float = 22.0
const RING_WIDTH: float = 6
const RING_SEGMENTS: int = 32

func _ready() -> void:
	#color = Color(0.08, 0.08, 0.12)
	#modulate = Color(1.1, 1.1, 1.1)

	# 创建经验进度环
	_create_exp_ring()

	# 连接经验变化信号
	Global.experience_changed.connect(_on_experience_changed)

	# 初始化显示
	_update_exp_ring(0.0)

## 创建经验进度环
func _create_exp_ring() -> void:
	# 外发光环
	exp_glow_ring = Line2D.new()
	exp_glow_ring.width = RING_WIDTH + 6
	exp_glow_ring.default_color = Color(0.2, 0.6, 1.0, 0.3)
	exp_glow_ring.joint_mode = Line2D.LINE_JOINT_ROUND
	exp_glow_ring.begin_cap_mode = Line2D.LINE_CAP_ROUND
	exp_glow_ring.end_cap_mode = Line2D.LINE_CAP_ROUND
	exp_glow_ring.position = Vector2(40, 40)
	add_child(exp_glow_ring)

	# 主进度环
	exp_progress_ring = Line2D.new()
	exp_progress_ring.width = RING_WIDTH
	exp_progress_ring.default_color = Color(0.4, 0.8, 2.0, 1.0)
	exp_progress_ring.joint_mode = Line2D.LINE_JOINT_ROUND
	exp_progress_ring.begin_cap_mode = Line2D.LINE_CAP_ROUND
	exp_progress_ring.end_cap_mode = Line2D.LINE_CAP_ROUND
	exp_progress_ring.position = Vector2(40, 40)
	add_child(exp_progress_ring)

## 经验变化回调
func _on_experience_changed(current_exp: int, exp_to_next: int, _player_level: int) -> void:
	var progress = float(current_exp) / float(exp_to_next) if exp_to_next > 0 else 0.0
	_update_exp_ring(progress)

## 更新经验进度环
func _update_exp_ring(progress: float) -> void:
	progress = clamp(progress, 0.0, 1.0)

	# 清除旧点
	exp_progress_ring.clear_points()
	exp_glow_ring.clear_points()

	if progress <= 0.0:
		return

	# 计算需要绘制的弧度（从顶部开始，顺时针）
	var start_angle = -PI / 2  # 从顶部开始
	var end_angle = start_angle + (progress * TAU)

	# 生成弧线点
	var segments = int(RING_SEGMENTS * progress) + 1
	segments = max(segments, 2)

	for i in range(segments + 1):
		var t = float(i) / float(segments)
		var angle = lerp(start_angle, end_angle, t)
		var point = Vector2(cos(angle), sin(angle)) * RING_RADIUS
		exp_progress_ring.add_point(point)
		exp_glow_ring.add_point(point)

	# 根据进度调整粒子效果强度
	if core_glow_particles:
		core_glow_particles.amount = int(lerp(8, 20, progress))
		# 接近满时更亮
		var glow_intensity = lerp(2.0, 4.0, progress)
		core_glow_particles.modulate = Color(0.5 * glow_intensity, 0.8 * glow_intensity, glow_intensity, 1.0)

	if orbit_particles:
		orbit_particles.amount = int(lerp(4, 10, progress))
		# 接近满时转得更快
		orbit_particles.angular_velocity_min = lerp(90.0, 180.0, progress)
		orbit_particles.angular_velocity_max = lerp(180.0, 360.0, progress)

## 升级时的特效（可由外部调用）
func play_level_up_effect() -> void:
	# 闪烁效果
	var tween = create_tween()
	tween.tween_property(exp_progress_ring, "default_color", Color(1.0, 1.0, 3.0, 1.0), 0.1)
	tween.tween_property(exp_progress_ring, "default_color", Color(0.4, 0.8, 2.0, 1.0), 0.3)

	# 发光环闪烁
	var glow_tween = create_tween()
	glow_tween.tween_property(exp_glow_ring, "default_color", Color(0.5, 0.8, 1.0, 0.8), 0.1)
	glow_tween.tween_property(exp_glow_ring, "default_color", Color(0.2, 0.6, 1.0, 0.3), 0.3)
