extends Area2D
class_name Projectile

@export var speed: float = 300.0
@export var damage: float = 10.0
@export var color: Color = Color(1, 0, 0)
var target_pos: Vector2 = Vector2.ZERO # 目标位置，用于初始化朝向

@export_group("Parry FX Burst")
## 近战化解时是否播放特效
@export var parry_fx_enabled: bool = true
## 化解特效粒子数量
@export var parry_fx_amount: int = 28
## 化解特效生命周期
@export var parry_fx_lifetime: float = 0.32
## 化解特效最小粒子尺寸
@export var parry_fx_scale_min: float = 4.8
## 化解特效最大粒子尺寸
@export var parry_fx_scale_max: float = 6.6
## 化解特效最小速度
@export var parry_fx_speed_min: float = 220.0
## 化解特效最大速度
@export var parry_fx_speed_max: float = 360.0
## 化解特效扩散角度
@export var parry_fx_spread: float = 180.0
## 是否使用飞行物颜色作为特效颜色
@export var parry_fx_use_projectile_color: bool = true
## 自定义特效颜色（当不使用飞行物颜色时）
@export var parry_fx_color: Color = Color(3.0, 1.2, 1.2, 1.0)
## 粒子亮度倍率（HDR）
@export var parry_fx_intensity: float = 1.6

@export_group("Parry FX Flash")
## 是否启用爆闪与冲击环
@export var parry_flash_enabled: bool = false
## 爆闪半径
@export var parry_flash_radius: float = 34.0
## 爆闪持续时长
@export var parry_flash_duration: float = 0.14
## 爆闪扩张倍率
@export var parry_flash_expand: float = 2.2
## 冲击环宽度
@export var parry_flash_ring_width: float = 6.0
## 爆闪是否使用飞行物颜色
@export var parry_flash_use_projectile_color: bool = true
## 自定义爆闪颜色（当不使用飞行物颜色时）
@export var parry_flash_color: Color = Color(3.8, 3.3, 3.0, 1.0)

@export_group("Parry FX Feedback")
## 化解时是否触发屏幕震动
@export var parry_screen_shake_enabled: bool = true
## 屏幕震动强度
@export var parry_screen_shake_intensity: float = 7.0
## 屏幕震动时长
@export var parry_screen_shake_duration: float = 0.1

func _ready() -> void:
	# 定时销毁
	var timer = get_tree().create_timer(4.0)
	timer.timeout.connect(queue_free)

	# 碰撞信号
	area_entered.connect(_on_area_entered)

	# 应用颜色到 Polygon2D
	var polygon = $Polygon2D
	if polygon:
		polygon.color = color

	# 如果目标位置已设置，设置朝向
	if target_pos != Vector2.ZERO:
		look_at(target_pos)
	else:
		rotation = PI # 默认向左

func _physics_process(delta: float) -> void:
	# 向当前朝向移动
	global_position += transform.x * speed * delta

func _on_area_entered(area: Area2D) -> void:
	# 检测是否击中Player的Hurtbox
	if area.name == "Hurtbox":
		var player = area.get_parent()
		if player.has_method("take_damage"):
			player.take_damage(damage)
			queue_free() # 销毁子弹

func destroy_by_melee_parry() -> void:
	# 明确反馈：化解特效 + 可选轻微屏幕震动
	if parry_fx_enabled:
		_spawn_parry_fx()
	if parry_screen_shake_enabled and Global and Global.has_method("request_screen_shake"):
		Global.request_screen_shake(parry_screen_shake_intensity, parry_screen_shake_duration)
	queue_free()

func _spawn_parry_fx() -> void:
	var host: Node = get_tree().current_scene
	if host == null:
		host = get_parent()
	if host == null:
		return

	var fx_root := Node2D.new()
	host.add_child(fx_root)
	fx_root.global_position = global_position

	var burst_color: Color = parry_fx_color
	if parry_fx_use_projectile_color:
		burst_color = color
	burst_color = Color(
		burst_color.r * parry_fx_intensity,
		burst_color.g * parry_fx_intensity,
		burst_color.b * parry_fx_intensity,
		1.0
	)

	var particles := CPUParticles2D.new()
	fx_root.add_child(particles)
	particles.one_shot = true
	particles.emitting = false
	particles.explosiveness = 1.0
	particles.amount = parry_fx_amount
	particles.lifetime = parry_fx_lifetime
	particles.direction = Vector2.ZERO
	particles.spread = parry_fx_spread
	particles.initial_velocity_min = parry_fx_speed_min
	particles.initial_velocity_max = parry_fx_speed_max
	particles.scale_amount_min = parry_fx_scale_min
	particles.scale_amount_max = parry_fx_scale_max
	particles.gravity = Vector2.ZERO
	particles.damping_min = 120.0
	particles.damping_max = 220.0
	particles.modulate = burst_color

	var scale_curve := Curve.new()
	scale_curve.add_point(Vector2(0.0, 1.0))
	scale_curve.add_point(Vector2(0.6, 0.55))
	scale_curve.add_point(Vector2(1.0, 0.0))
	particles.scale_amount_curve = scale_curve

	particles.restart()
	particles.emitting = true

	if parry_flash_enabled:
		_spawn_parry_flash(fx_root)

	var cleanup_time: float = maxf(parry_fx_lifetime + 0.45, parry_flash_duration + 0.2)
	get_tree().create_timer(cleanup_time).timeout.connect(fx_root.queue_free)

func _spawn_parry_flash(parent: Node2D) -> void:
	var flash_color: Color = parry_flash_color
	if parry_flash_use_projectile_color:
		flash_color = color
	flash_color.a = 1.0

	var core := Polygon2D.new()
	core.polygon = _build_circle_polygon(parry_flash_radius, 18)
	core.color = flash_color
	core.modulate.a = 0.8
	core.scale = Vector2.ONE * 0.35
	parent.add_child(core)

	var ring := Line2D.new()
	ring.width = parry_flash_ring_width
	ring.closed = true
	ring.default_color = flash_color
	ring.modulate.a = 0.95
	ring.antialiased = true
	ring.joint_mode = Line2D.LINE_JOINT_ROUND
	ring.begin_cap_mode = Line2D.LINE_CAP_ROUND
	ring.end_cap_mode = Line2D.LINE_CAP_ROUND
	ring.points = _build_circle_polygon(parry_flash_radius * 0.85, 24)
	ring.scale = Vector2.ONE * 0.55
	parent.add_child(ring)

	var tween := parent.create_tween()
	tween.set_parallel(true)
	tween.tween_property(core, "scale", Vector2.ONE * parry_flash_expand, parry_flash_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(core, "modulate:a", 0.0, parry_flash_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(ring, "scale", Vector2.ONE * (parry_flash_expand + 0.4), parry_flash_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(ring, "modulate:a", 0.0, parry_flash_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _build_circle_polygon(radius: float, segments: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	var valid_segments: int = max(segments, 6)
	for i in range(valid_segments):
		var t: float = float(i) / float(valid_segments)
		var angle: float = t * TAU
		points.push_back(Vector2(cos(angle), sin(angle)) * radius)
	return points
