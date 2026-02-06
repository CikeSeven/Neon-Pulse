class_name Bullet extends Node2D

## 子弹飞行速度
@export var speed: float = 1200
## 子弹基础伤害
@export var damage: float = 6
## 子弹击退强度
@export var knockback: float = 10.0
## 子弹存活时间
@export var lifetime: float = 10.0
## 能穿透多少敌人
@export var penetration_times: int = 1

@export_group("Hit Effect")
@export var hit_effect_enabled: bool = true
@export var hit_effect_amount: int = 8
@export var hit_effect_lifetime: float = 0.2
@export var hit_effect_color: Color = Color(4.0, 1.2, 0.4, 1.0)
@export var hit_effect_scale_min: float = 1.0
@export var hit_effect_scale_max: float = 2.0
@export var hit_effect_spread: float = 30.0
@export var hit_effect_speed_min: float = 60.0
@export var hit_effect_speed_max: float = 120.0
@export var hit_effect_angular_velocity_min: float = 0.0
@export var hit_effect_angular_velocity_max: float = 0.0
@export var hit_effect_gravity: Vector2 = Vector2.ZERO
@export var hit_effect_cleanup_delay: float = 0.5
@export var hit_effect_direction: Vector2 = Vector2.LEFT

var last_hit_position: Vector2 = Vector2.ZERO


@onready var hitbox: Hitbox = $Hitbox

func _ready() -> void:
	# 设置自动销毁计时器（防止飞出屏幕太远不销毁的兜底策略）
	get_tree().create_timer(lifetime).timeout.connect(queue_free)
	hitbox.damage = damage
	hitbox.knockback = knockback
	hitbox.hit.connect(_on_hitbox_hit)

func _physics_process(delta: float) -> void:
	# 移动逻辑：默认向右
	position += transform.x * speed * delta



func _on_hitbox_hit(hurtbox: Hurtbox) -> void:
	last_hit_position = hurtbox.global_position
	create_hit_effect()

	if penetration_times < 0:
		return

	# 扣除穿透次数
	penetration_times -= 1
	# 如果穿透次数用尽，销毁子弹
	if penetration_times <= 0:
		# 延迟一帧销毁，或者直接销毁
		# 建议先把 Hitbox 关掉防止一帧内多次触发，然后销毁
		hitbox.set_deferred("monitorable", false)
		queue_free()



# 击中特效（由导出参数控制）
func create_hit_effect() -> void:
	if not hit_effect_enabled:
		return

	var particles = CPUParticles2D.new()
	particles.emitting = false
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.amount = hit_effect_amount
	particles.lifetime = hit_effect_lifetime

	particles.modulate = hit_effect_color
	particles.scale_amount_min = hit_effect_scale_min
	particles.scale_amount_max = hit_effect_scale_max
	particles.direction = hit_effect_direction.rotated(rotation)
	particles.spread = hit_effect_spread
	particles.initial_velocity_min = hit_effect_speed_min
	particles.initial_velocity_max = hit_effect_speed_max
	particles.gravity = hit_effect_gravity
	particles.angular_velocity_min = hit_effect_angular_velocity_min
	particles.angular_velocity_max = hit_effect_angular_velocity_max

	get_tree().current_scene.add_child(particles)
	particles.global_position = last_hit_position
	particles.restart()
	particles.emitting = true

	get_tree().create_timer(hit_effect_cleanup_delay).timeout.connect(particles.queue_free)
