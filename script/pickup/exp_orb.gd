extends PickupBase
class_name ExpOrb

## 经验掉落物
## 继承自 PickupBase

const EXP_VALUE: int = 10  ## 每个经验球代表10经验

func get_pickup_range() -> float:
	return Global.exp_range

func get_particle_color() -> Color:
	return Color(0.3, 2.0, 0.5, 1.0)  # 绿色粒子

func on_collected() -> void:
	Global.add_experience(EXP_VALUE)
