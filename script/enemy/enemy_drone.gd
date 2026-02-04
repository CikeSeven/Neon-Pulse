class_name EnemyDrone extends Enemy

## 无人机型敌人（基础敌人）
## 只是简单地向左移动，没有特殊行为
## 作为基础敌人类型的父类

func _physics_process(delta: float) -> void:
	if is_hit_frozen:
		return

	position.x -= speed * delta

	# 屏幕外销毁计时
	_update_offscreen_timer(delta)
