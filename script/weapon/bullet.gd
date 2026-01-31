class_name Bullet extends Node2D

## 子弹飞行速度
@export var speed: float = 1200
## 子弹基础伤害
@export var damage: float = 6
## 子弹存活时间
@export var lifetime: float = 15.0
## 能穿透多少敌人
@export var penetration_times: int = 1 


@onready var hitbox: Hitbox = $Hitbox

func _ready() -> void:
	# 设置自动销毁计时器（防止飞出屏幕太远不销毁的兜底策略）
	get_tree().create_timer(lifetime).timeout.connect(queue_free)
	hitbox.damage = damage
	hitbox.hit.connect(_on_hitbox_hit)

func _physics_process(delta: float) -> void:
	# 移动逻辑：默认向右
	position += transform.x * speed * delta



func _on_hitbox_hit(_hurtbox: Hurtbox) -> void:
	# 扣除穿透次数
	penetration_times -= 1
	# 如果穿透次数用尽，销毁子弹
	if penetration_times <= 0:
		create_hit_effect()
		
		# 延迟一帧销毁，或者直接销毁
		# 建议先把 Hitbox 关掉防止一帧内多次触发，然后销毁
		hitbox.set_deferred("monitorable", false)
		queue_free()



# 虚函数：击中特效（子类可以覆盖这个函数来实现不同的爆炸效果）
func create_hit_effect() -> void:
	pass
