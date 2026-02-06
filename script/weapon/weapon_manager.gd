class_name WeaponManager extends Node2D

# --- 武器数据库 (ID对照表) ---
# 使用 Dictionary 存储 ID -> 场景路径 的映射
# 使用 preload 预加载可以提高运行时性能，但如果武器太多，可以改用 load()
const WEAPON_DB = {
	1001: preload("res://scene/weapon/neon_ak.tscn"),
	1002: preload("res://scene/weapon/laser_gun.tscn"),
	1003: preload("res://scene/weapon/energy_blade.tscn"),
	
}

func _ready() -> void:
	# TODO测试用
	add_weapon(1002)

# --- 核心函数：添加武器 ---
func add_weapon(weapon_id: int) -> void:
	if not WEAPON_DB.has(weapon_id):
		push_error("WeaponManager: 未知的武器ID %d" % weapon_id)
		return
	
	# 1. 实例化武器
	var weapon_scene = WEAPON_DB[weapon_id]
	var new_weapon = weapon_scene.instantiate()
	
	# 2. 添加到自身节点下
	add_child(new_weapon)
	
	# 3. 刷新武器节点状态（不做环绕，仅用于持有/统计）
	refresh_weapons()

# --- 辅助函数：刷新武器节点 ---
func refresh_weapons() -> void:
	var weapons = get_children()
	for weapon in weapons:
		weapon.position = Vector2.ZERO
		weapon.rotation = 0.0
