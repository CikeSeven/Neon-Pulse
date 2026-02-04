extends Area2D
class_name PickupBase

## 掉落物基类
## 玩家靠近时会被吸引并拾取
## 掉落物会向左移动，模拟玩家向右前进的效果

@export var pickup_speed: float = 600.0  ## 吸引速度
@export var initial_scatter_speed: float = 200.0  ## 初始散射速度

var is_being_collected: bool = false
var velocity: Vector2 = Vector2.ZERO
var scatter_timer: float = 0.3  ## 散射持续时间

## 子类需要重写此方法返回拾取范围
func get_pickup_range() -> float:
	return 150.0

## 子类需要重写此方法处理拾取逻辑
func on_collected() -> void:
	pass

## 子类需要重写此方法返回粒子颜色
func get_particle_color() -> Color:
	return Color(1.0, 1.0, 1.0, 1.0)

func _ready() -> void:
	# 初始散射效果
	var random_angle = randf() * TAU
	velocity = Vector2.from_angle(random_angle) * initial_scatter_speed

func _physics_process(delta: float) -> void:
	var player = Global.player_ref
	var pickup_range = get_pickup_range()

	# 散射计时
	if scatter_timer > 0:
		scatter_timer -= delta

	if not player:
		# 没有玩家时向左移动
		velocity.x = -Global.world_scroll_speed
		velocity.y *= 0.9
		global_position += velocity * delta
		return

	var distance_to_player = global_position.distance_to(player.global_position)

	if distance_to_player <= pickup_range or is_being_collected:
		# 进入吸引范围，开始向玩家移动
		is_being_collected = true
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * pickup_speed
		global_position += velocity * delta

		# 非常接近时直接拾取
		if distance_to_player < 30:
			_collect()
	else:
		# 散射结束后，向左移动
		if scatter_timer <= 0:
			velocity.x = lerp(velocity.x, -Global.world_scroll_speed, 0.1)
			velocity.y *= 0.9
		else:
			velocity *= 0.95

		global_position += velocity * delta

	# 超出屏幕左侧时销毁
	if global_position.x < -1200:
		queue_free()

func _collect() -> void:
	# 调用子类的拾取逻辑
	on_collected()

	# 播放拾取特效
	_spawn_collect_particles()

	# 销毁自身
	queue_free()

func _spawn_collect_particles() -> void:
	var particles = CPUParticles2D.new()
	particles.emitting = false
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.amount = 8
	particles.lifetime = 0.3

	# 使用子类定义的颜色
	particles.modulate = get_particle_color()
	particles.scale_amount_min = 3.0
	particles.scale_amount_max = 6.0

	# 粒子由大到小消散
	var curve = Curve.new()
	curve.add_point(Vector2(0.0, 1.0))
	curve.add_point(Vector2(1.0, 0.0))
	particles.scale_amount_curve = curve

	# 向外扩散
	particles.direction = Vector2.ZERO
	particles.spread = 180.0
	particles.initial_velocity_min = 50.0
	particles.initial_velocity_max = 100.0
	particles.gravity = Vector2.ZERO
	particles.damping_min = 100.0
	particles.damping_max = 150.0

	get_tree().current_scene.add_child(particles)
	particles.global_position = global_position
	particles.restart()
	particles.emitting = true

	# 自动清理
	get_tree().create_timer(1.0).timeout.connect(particles.queue_free)
