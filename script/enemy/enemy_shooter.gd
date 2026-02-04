class_name EnemyShooter extends Enemy

## 射击型敌人（基类）
## 定期向玩家发射子弹，只有玩家在前方扇形区域内才会射击
## 作为射击型敌人的父类

enum ShooterState {
	IDLE,
	COOLDOWN,
}

@export_group("Shooter")
@export var shoot_interval: float = 4.0 ## 射击间隔
@export var bullet_speed: float = 400.0 ## 子弹速度
@export var bullet_damage: float = 10.0 ## 子弹伤害
@export var bullet_color: Color = Color(3.0, 0.2, 0.2, 1.0) ## 子弹颜色（鲜红）
@export var shoot_angle: float = 60.0 ## 射击扇形角度（单边，总角度为2倍）
@export var shoot_range: float = 800.0 ## 射击范围

var shooter_state: ShooterState = ShooterState.IDLE
var shoot_timer: float = 0.0

func _ready() -> void:
	super._ready()
	# 覆盖默认速度，射击敌人通常移动较慢
	if speed == 150.0:
		speed = 80.0

func _physics_process(delta: float) -> void:
	if is_hit_frozen:
		return

	match shooter_state:
		ShooterState.IDLE:
			_process_idle(delta)
		ShooterState.COOLDOWN:
			_process_cooldown(delta)

	# 屏幕外销毁计时
	_update_offscreen_timer(delta)

func _process_idle(delta: float) -> void:
	# 正常向左移动
	position.x -= speed * delta

	# 计时射击
	shoot_timer -= delta
	if shoot_timer <= 0:
		_try_shoot()

func _process_cooldown(delta: float) -> void:
	# 移动速度减半
	position.x -= (speed * 0.5) * delta

	# 冷却计时
	shoot_timer -= delta
	if shoot_timer <= 0:
		shooter_state = ShooterState.IDLE
		shoot_timer = shoot_interval

func _try_shoot() -> void:
	var player = Global.player_ref
	if not player:
		return

	# 计算玩家相对于敌人的方向
	var to_player = player.global_position - global_position

	# 检查玩家是否在前方（敌人面向左边，所以玩家x应该小于敌人x）
	if to_player.x > 0:
		# 玩家在敌人后方，不射击
		shoot_timer = 0.5  # 短暂等待后重试
		return

	# 检查距离
	var distance = to_player.length()
	if distance > shoot_range:
		# 玩家太远，不射击
		shoot_timer = 0.5
		return

	# 计算角度（敌人面向左边，即 -x 方向）
	var forward_dir = Vector2(-1, 0)  # 敌人面向左
	var angle_to_player = rad_to_deg(forward_dir.angle_to(to_player))

	# 检查是否在扇形范围内
	if abs(angle_to_player) <= shoot_angle:
		_shoot_bullet(player.global_position)

		# 进入短暂冷却
		shooter_state = ShooterState.COOLDOWN
		shoot_timer = 0.5  # 射击后停顿0.5秒
	else:
		# 玩家不在射击范围内，短暂等待后重试
		shoot_timer = 0.3

func _shoot_bullet(target_pos: Vector2) -> void:
	var projectile_scene = load("res://scene/projectile.tscn")
	var bullet = projectile_scene.instantiate()

	bullet.position = global_position
	bullet.target_pos = target_pos  # 设置目标位置以确定方向
	bullet.speed = bullet_speed
	bullet.damage = bullet_damage
	bullet.color = bullet_color

	get_parent().add_child(bullet)

	# 视觉反馈：发射时闪烁
	_play_shoot_effect()

func _play_shoot_effect() -> void:
	if not visuals:
		return

	var tween = create_tween()
	tween.tween_property(visuals, "modulate", Color(5.0, 5.0, 5.0), 0.05)
	tween.tween_property(visuals, "modulate", Color.WHITE, 0.15)

func _get_current_lane() -> int:
	var min_distance = INF
	var closest_lane = 0

	for i in range(Global.lane_y_positions.size()):
		var distance = abs(position.y - Global.lane_y_positions[i])
		if distance < min_distance:
			min_distance = distance
			closest_lane = i

	return closest_lane
