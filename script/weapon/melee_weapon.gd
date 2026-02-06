class_name MeleeWeapon extends Node2D

@export_group("Combat")
## 单次挥砍基础伤害
@export var damage: float = 7.0
## 单次挥砍击退强度
@export var knockback: float = 40.0
## 两次挥砍之间的冷却时间（秒）
@export var cooldown: float = 0.75

@export_group("Slash Path")
## 挥砍总时长（秒）
@export var slash_duration: float = 0.25
## 挥砍起始角度（度）
@export var slash_start_angle_deg: float = -96.0
## 挥砍结束角度（度）
@export var slash_end_angle_deg: float = 110.0
## 刀光拖尾覆盖角度（度）
@export var slash_trail_span_deg: float = 170.0
## 椭圆轨道中心偏移（相对玩家）
@export var ellipse_center: Vector2 = Vector2(64.0, 0)
## 椭圆轨道半径（x=横向半径，y=纵向半径）
@export var ellipse_radius: Vector2 = Vector2(170.0, 132.0)
## 刀光弧线采样段数（越大越平滑）
@export var arc_segments: int = 32

@export_group("Hitbox")
## 挥砍判定框尺寸
@export var hitbox_size: Vector2 = Vector2(188.0, 188.0)
## 判定框沿刀尖切线的前推距离
@export var hitbox_forward_offset: float = 14.0
## 判定框在玩家身后额外覆盖距离，避免贴脸漏判
@export var hitbox_back_padding: float = 18.0
## 是否让判定宽度随当前刀光覆盖角度增长
@export var hitbox_grow_with_coverage: bool = true
## 覆盖到满角度时，判定宽度相对基础宽度的倍率
@export var hitbox_width_growth_ratio: float = 2.5
## 判定宽度上限，防止极端角度下过大
@export var hitbox_width_max: float = 420.0
## 是否可以通过近战挥砍化解敌方飞行物
@export var can_destroy_enemy_projectiles: bool = true

@export_group("Coverage Hitbox")
## 是否启用额外固定宽度判定（覆盖玩家到刀光区域）
@export var coverage_hitbox_enabled: bool = true
## 额外判定框尺寸（Y为固定宽度）
@export var coverage_hitbox_size: Vector2 = Vector2(188.0, 88.0)
## 额外判定框前推距离
@export var coverage_hitbox_forward_offset: float = 14.0
## 额外判定框后向补偿
@export var coverage_hitbox_back_padding: float = 18.0

@export_group("Slash Visual")
## 外层刀光基础宽度（曲线的乘数）
@export var slash_outer_width: float = 64.0
## 核心刀光基础宽度（曲线的乘数）
@export var slash_core_width: float = 22.0

# --- 修改开始：替换旧参数为资源 ---
## 外层刀光颜色渐变（控制颜色和透明度随长度的变化）
@export var slash_outer_gradient: Gradient
## 外层刀光宽度曲线（控制形状，0-1范围）
@export var slash_outer_curve: Curve

## 核心刀光颜色渐变
@export var slash_core_gradient: Gradient
## 核心刀光宽度曲线
@export var slash_core_curve: Curve


@export_group("Slash Particles")
## 是否启用挥砍粒子
@export var particle_enabled: bool = true
## 挥砍粒子数量
@export var particle_amount: int = 64
## 挥砍粒子生命周期（秒）
@export var particle_lifetime: float = 0.34
## 挥砍粒子扩散角
@export var particle_spread: float = 34.0
## 挥砍粒子颜色（支持HDR发光）
@export var particle_color: Color = Color(0.65, 1.15, 3.2)
## 挥砍粒子最小速度
@export var particle_speed_min: float = 190.0
## 挥砍粒子最大速度
@export var particle_speed_max: float = 190.0
## 挥砍粒子最小尺寸
@export var particle_scale_min: float = 2.4
## 挥砍粒子最大尺寸
@export var particle_scale_max: float = 5.2

@onready var cooldown_timer: Timer = $CooldownTimer
@onready var hitbox: Hitbox = $Hitbox
@onready var hitbox_shape: CollisionShape2D = $Hitbox/CollisionShape2D
@onready var slash_arc: Line2D = $SlashFx/SlashArc
@onready var slash_arc_core: Line2D = $SlashFx/SlashArcCore
@onready var slash_particles: CPUParticles2D = $SlashFx/SlashParticles

var is_slashing: bool = false
var slash_elapsed: float = 0.0
var coverage_hitbox: Hitbox
var coverage_hitbox_shape: CollisionShape2D
const ENEMY_HURTBOX_MASK: int = 1 << 5  # Layer 6
const ENEMY_PROJECTILE_MASK: int = 1 << 6  # Layer 7

func _ready() -> void:
	_ensure_coverage_hitbox()

	hitbox.damage = damage
	hitbox.knockback = knockback
	_configure_hitbox_collision_mask()
	hitbox.area_entered.connect(_on_hitbox_area_entered)
	if coverage_hitbox:
		coverage_hitbox.damage = damage
		coverage_hitbox.knockback = knockback
		coverage_hitbox.area_entered.connect(_on_hitbox_area_entered)
	_configure_hitbox_shape()
	_configure_coverage_hitbox_shape()
	_configure_slash_visual()
	_configure_particles()

	_set_hitbox_enabled(false)
	_set_slash_visible(false)

	cooldown_timer.one_shot = false
	cooldown_timer.wait_time = cooldown
	cooldown_timer.timeout.connect(_on_cooldown_timeout)
	cooldown_timer.start()

func _process(delta: float) -> void:
	if not is_slashing:
		return

	slash_elapsed += delta
	var t: float = minf(slash_elapsed / maxf(slash_duration, 0.001), 1.0)
	var eased_t: float = 1.0 - pow(1.0 - t, 3.0)

	_update_slash_state(eased_t)

	if t >= 1.0:
		_end_slash()

func _on_cooldown_timeout() -> void:
	if is_slashing:
		return
	_begin_slash()

func _begin_slash() -> void:
	is_slashing = true
	slash_elapsed = 0.0

	hitbox.damage = damage
	hitbox.knockback = knockback
	if coverage_hitbox:
		coverage_hitbox.damage = damage
		coverage_hitbox.knockback = knockback
	_update_slash_state(0.0)
	_set_hitbox_enabled(true)
	_set_slash_visible(true)

	if particle_enabled:
		slash_particles.emitting = false
		slash_particles.restart()
		slash_particles.emitting = true

func _end_slash() -> void:
	is_slashing = false
	slash_elapsed = 0.0
	_set_hitbox_enabled(false)
	_set_slash_visible(false)
	slash_particles.emitting = false

func _set_hitbox_enabled(enabled: bool) -> void:
	hitbox.visible = enabled
	hitbox.monitoring = enabled
	hitbox.monitorable = enabled
	if coverage_hitbox:
		var coverage_enabled: bool = enabled and coverage_hitbox_enabled
		coverage_hitbox.visible = coverage_enabled
		coverage_hitbox.monitoring = coverage_enabled
		coverage_hitbox.monitorable = coverage_enabled

func _set_slash_visible(enabled: bool) -> void:
	slash_arc.visible = enabled
	slash_arc_core.visible = enabled

func _configure_hitbox_collision_mask() -> void:
	# 主Hitbox专注于刀光贴边判定；覆盖型Hitbox负责主体敌人判定，避免双倍伤害
	var using_coverage_hitbox: bool = coverage_hitbox != null and coverage_hitbox_enabled
	var main_mask: int = ENEMY_HURTBOX_MASK if not using_coverage_hitbox else 0
	if can_destroy_enemy_projectiles:
		main_mask |= ENEMY_PROJECTILE_MASK
	hitbox.collision_mask = main_mask

	if using_coverage_hitbox:
		var coverage_mask: int = ENEMY_HURTBOX_MASK
		if can_destroy_enemy_projectiles:
			coverage_mask |= ENEMY_PROJECTILE_MASK
		coverage_hitbox.collision_mask = coverage_mask

func _configure_hitbox_shape() -> void:
	var shape: RectangleShape2D = hitbox_shape.shape as RectangleShape2D
	if shape == null:
		shape = RectangleShape2D.new()
		hitbox_shape.shape = shape
	shape.size = hitbox_size

func _configure_coverage_hitbox_shape() -> void:
	if not coverage_hitbox or not coverage_hitbox_shape:
		return

	var shape: RectangleShape2D = coverage_hitbox_shape.shape as RectangleShape2D
	if shape == null:
		shape = RectangleShape2D.new()
		coverage_hitbox_shape.shape = shape
	shape.size = coverage_hitbox_size

func _ensure_coverage_hitbox() -> void:
	if not coverage_hitbox_enabled:
		return

	coverage_hitbox = get_node_or_null("CoverageHitbox") as Hitbox
	if coverage_hitbox == null:
		coverage_hitbox = Hitbox.new()
		coverage_hitbox.name = "CoverageHitbox"
		coverage_hitbox.collision_layer = 0
		add_child(coverage_hitbox)

	coverage_hitbox_shape = coverage_hitbox.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if coverage_hitbox_shape == null:
		coverage_hitbox_shape = CollisionShape2D.new()
		coverage_hitbox_shape.name = "CollisionShape2D"
		coverage_hitbox.add_child(coverage_hitbox_shape)

func _on_hitbox_area_entered(area: Area2D) -> void:
	if not can_destroy_enemy_projectiles or not is_slashing:
		return

	var projectile: Projectile = area as Projectile
	if projectile == null and area.get_parent() is Projectile:
		projectile = area.get_parent() as Projectile

	if projectile and not projectile.is_queued_for_deletion():
		if projectile.has_method("destroy_by_melee_parry"):
			projectile.call_deferred("destroy_by_melee_parry")
		else:
			projectile.queue_free()

func _configure_slash_visual() -> void:
	# 设置基础宽度（缩放因子）
	slash_arc.width = slash_outer_width
	slash_arc_core.width = slash_core_width
		
	# 直接应用导出的资源
	# 注意：为了防止未赋值报错，建议在编辑器里手动新建资源，或者加个判空
	if slash_outer_curve:
		slash_arc.width_curve = slash_outer_curve
	if slash_core_curve:
		slash_arc_core.width_curve = slash_core_curve
				
	if slash_outer_gradient:
		slash_arc.gradient = slash_outer_gradient
	if slash_core_gradient:
		slash_arc_core.gradient = slash_core_gradient

func _configure_particles() -> void:
	slash_particles.emitting = false
	slash_particles.one_shot = false
	slash_particles.explosiveness = 0
	slash_particles.amount = particle_amount
	slash_particles.lifetime = particle_lifetime
	slash_particles.spread = particle_spread
	slash_particles.modulate = particle_color
	slash_particles.initial_velocity_min = particle_speed_min
	slash_particles.initial_velocity_max = particle_speed_max
	slash_particles.scale_amount_min = particle_scale_min
	slash_particles.scale_amount_max = particle_scale_max
	slash_particles.local_coords = false
	slash_particles.gravity = Vector2.ZERO

func _update_slash_state(progress: float) -> void:
	var current_angle_deg: float = lerpf(slash_start_angle_deg, slash_end_angle_deg, progress)
	var arc_from_deg: float = maxf(slash_start_angle_deg, current_angle_deg - slash_trail_span_deg)
	var arc_to_deg: float = current_angle_deg
	var covered_span_deg: float = absf(arc_to_deg - arc_from_deg)

	var arc_points: PackedVector2Array = _build_ellipse_arc_points(arc_from_deg, arc_to_deg)
	slash_arc.points = arc_points
	slash_arc_core.points = arc_points

	var alpha_fade: float = 1.0 - pow(progress, 5.0)
	slash_arc.modulate.a = alpha_fade
	slash_arc_core.modulate.a = alpha_fade

	var tip: Vector2 = _ellipse_point_deg(current_angle_deg)
	var tangent: Vector2 = _ellipse_tangent_deg(current_angle_deg).normalized()
	var mid_angle_deg: float = (arc_from_deg + arc_to_deg) * 0.5
	var follow_point: Vector2 = _ellipse_point_deg(mid_angle_deg)

	# 判定范围覆盖“玩家位置 -> 当前刀光覆盖中点”，宽度固定不变
	var origin_to_follow: Vector2 = follow_point
	var radial_dir: Vector2 = origin_to_follow.normalized()
	if radial_dir == Vector2.ZERO:
		radial_dir = Vector2.RIGHT

	var front_edge: float = origin_to_follow.length() + hitbox_forward_offset
	var back_edge: float = -hitbox_back_padding
	var dynamic_length: float = maxf(front_edge - back_edge, hitbox_size.x)
	var center_distance: float = (front_edge + back_edge) * 0.5
	var dynamic_width: float = hitbox_size.y
	if hitbox_grow_with_coverage:
		var full_span_deg: float = maxf(absf(slash_trail_span_deg), 0.001)
		var coverage_t: float = clampf(covered_span_deg / full_span_deg, 0.0, 1.0)
		var target_width: float = hitbox_size.y * maxf(hitbox_width_growth_ratio, 1.0)
		dynamic_width = lerpf(hitbox_size.y, target_width, coverage_t)
		dynamic_width = minf(dynamic_width, hitbox_width_max)

	var shape: RectangleShape2D = hitbox_shape.shape as RectangleShape2D
	if shape:
		shape.size = Vector2(dynamic_length, dynamic_width)

	hitbox.position = radial_dir * center_distance
	hitbox.rotation = radial_dir.angle()

	if coverage_hitbox and coverage_hitbox_enabled and coverage_hitbox_shape:
		# 固定宽度判定框跟随刀光头部（tip），而不是覆盖中点
		var coverage_origin_to_tip: Vector2 = tip
		var coverage_radial_dir: Vector2 = coverage_origin_to_tip.normalized()
		if coverage_radial_dir == Vector2.ZERO:
			coverage_radial_dir = radial_dir

		var coverage_front_edge: float = coverage_origin_to_tip.length() + coverage_hitbox_forward_offset
		var coverage_back_edge: float = -coverage_hitbox_back_padding
		var coverage_length: float = maxf(coverage_front_edge - coverage_back_edge, coverage_hitbox_size.x)
		var coverage_center_distance: float = (coverage_front_edge + coverage_back_edge) * 0.5
		var coverage_shape: RectangleShape2D = coverage_hitbox_shape.shape as RectangleShape2D
		if coverage_shape:
			coverage_shape.size = Vector2(coverage_length, coverage_hitbox_size.y)
		coverage_hitbox.position = coverage_radial_dir * coverage_center_distance
		coverage_hitbox.rotation = coverage_radial_dir.angle()

	slash_particles.position = tip
	slash_particles.direction = tangent

func _build_ellipse_arc_points(from_deg: float, to_deg: float) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	var segments: int = arc_segments if arc_segments > 4 else 4

	for i in range(segments + 1):
		var t: float = float(i) / float(segments)
		var angle_deg: float = lerpf(from_deg, to_deg, t)
		points.push_back(_ellipse_point_deg(angle_deg))

	return points

func _ellipse_point_deg(angle_deg: float) -> Vector2:
	var angle: float = deg_to_rad(angle_deg)
	return ellipse_center + Vector2(cos(angle) * ellipse_radius.x, sin(angle) * ellipse_radius.y)

func _ellipse_tangent_deg(angle_deg: float) -> Vector2:
	var angle: float = deg_to_rad(angle_deg)
	return Vector2(-ellipse_radius.x * sin(angle), ellipse_radius.y * cos(angle))
