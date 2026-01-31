class_name Weapon extends Node2D

## 武器所使用的子弹
@export var bullet_scene: PackedScene 

## 射速
@export var fire_rate: float = 0.3
## 散射值 
@export var spread_angle: float = 0.0 

@onready var cooldown_timer: Timer = $CooldownTimer
@onready var muzzle: Marker2D = $Muzzle

func _ready() -> void:
	# 设为非 One Shot (循环触发)
	cooldown_timer.one_shot = false
	# 设置时间间隔
	cooldown_timer.wait_time = fire_rate
	# 连接超时信号到射击函数
	cooldown_timer.timeout.connect(_on_timer_timeout)
	# 武器生成即开火
	cooldown_timer.start()
	

## 计时器回调，发射子弹后触发
func _on_timer_timeout() -> void:
	spawn_projectile()


## 生成子弹
func spawn_projectile() -> void:
	if not bullet_scene:
		return
	
	var bullet = bullet_scene.instantiate() as Bullet
	bullet.global_position = muzzle.global_position
	
	var random_spread = randf_range(-spread_angle, spread_angle)
	bullet.rotation = global_rotation + deg_to_rad(random_spread)
	
	get_tree().current_scene.add_child(bullet)
	play_shoot_effect()

## 射击特效
func play_shoot_effect() -> void:
	pass
