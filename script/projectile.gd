extends Area2D
class_name Projectile

var speed: float = 300.0
var damage: float = 10.0
var color: Color = Color(1, 0, 0)
var target_pos: Vector2 = Vector2.ZERO # 目标位置，用于初始化朝向

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
