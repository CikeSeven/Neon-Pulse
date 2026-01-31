class_name WeaponManager extends Node2D

# --- 武器数据库 (ID对照表) ---
# 使用 Dictionary 存储 ID -> 场景路径 的映射
# 使用 preload 预加载可以提高运行时性能，但如果武器太多，可以改用 load()
const WEAPON_DB = {
	1001: preload("res://scene/weapon/neon_ak.tscn"),
	1002: preload("res://scene/weapon/laser_gun.tscn"),
	
}

# --- 武器槽位管理 ---
# 定义武器围绕玩家的半径
@export var orbit_radius: float = 60.0 

func _ready() -> void:
	# 测试用：游戏开始时自动送一把 AK
	add_weapon(1001)

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
	
	# 3. 重新排列所有武器的位置 (形成环绕或其他阵型)
	rearrange_weapons()

# --- 辅助函数：排列武器 ---
# 当获得新武器时，自动重新计算所有武器的位置，避免重叠
func rearrange_weapons() -> void:
	var weapons = get_children()
	var count = weapons.size()
	
	if count == 0:
		return
		
	# 简单的环绕排列算法：将所有武器均匀分布在圆周上
	var step_angle = 2 * PI / count
	
	for i in range(count):
		var weapon = weapons[i]
		# 计算角度
		var current_angle = i * step_angle
		# 设置位置 (极坐标转笛卡尔坐标)
		var target_pos = Vector2(cos(current_angle), sin(current_angle)) * orbit_radius
		
		# 直接设置位置，或者使用 Tween 做一个平滑移动效果
		weapon.position = target_pos
		
		# 可选：让武器枪口朝外 (旋转武器)
		weapon.rotation = current_angle
