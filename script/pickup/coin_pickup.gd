extends PickupBase
class_name CoinPickup

## 金币掉落物
## 继承自 PickupBase

const COIN_VALUE: int = 1  ## 每个金币代表1金币

func get_pickup_range() -> float:
	return Global.coin_range

func get_particle_color() -> Color:
	return Color(2.0, 1.7, 0.3, 1.0)  # 金色粒子

func on_collected() -> void:
	Global.add_gold(COIN_VALUE)
