class_name Enemy extends Node2D


@export var speed: float = 150
@export var max_hp: float = 30.0 ## 怪物血量
@export var contact_damage: float = 10.0 ## 敌人撞玩家造成的伤害
@export var hp_size: Vector2 = Vector2(80, 2) ## 血条UI大小

@export_group("Loot")
@export var is_elite: bool = false ## 是否为精英怪
@export var exp_drop_chance: float = 0.6 ## 普通怪掉落经验概率 (0-1)
@export var coin_drop_chance: float = 0.4 ## 普通怪掉落金币概率 (0-1)

@export_group("Hit Effects")
@export var hit_flash_color: Color = Color(0.3, 2.0, 3.0, 1.0) ## 受击闪烁颜色（青色霓虹）
@export var hit_flash_duration: float = 0.15 ## 闪烁持续时间
@export var hit_flash_recover_color: Color = Color.WHITE ## 闪烁结束后恢复颜色
@export var knockback_strength: float = 30.0 ## 击退强度
@export var hit_freeze_duration: float = 0.05 ## 受击顿帧时间

@export_group("Hit Particles")
@export var hit_particle_color: Color = Color(0.5, 2.0, 3.0, 1.0) ## 受击粒子颜色
@export var hit_particle_amount: int = 12 ## 受击粒子数量
@export var hit_particle_lifetime: float = 0.5 ## 受击粒子生命周期
@export var hit_particle_scale_min: float = 4.0 ## 受击粒子最小尺寸
@export var hit_particle_scale_max: float = 8.0 ## 受击粒子最大尺寸
@export var hit_particle_velocity_min: float = 100.0 ## 受击粒子最小速度
@export var hit_particle_velocity_max: float = 200.0 ## 受击粒子最大速度

@export_group("Death Particles")
@export var death_particle_color: Color = Color(0.5, 2.5, 4.0, 1.0) ## 死亡粒子颜色
@export var death_particle_amount: int = 30 ## 死亡粒子数量
@export var death_particle_lifetime: float = 0.8 ## 死亡粒子生命周期
@export var death_particle_scale_min: float = 6.0 ## 死亡粒子最小尺寸
@export var death_particle_scale_max: float = 12.0 ## 死亡粒子最大尺寸
@export var death_particle_velocity_min: float = 150.0 ## 死亡粒子最小速度
@export var death_particle_velocity_max: float = 350.0 ## 死亡粒子最大速度

# --- 节点引用 ---
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var hitbox: Hitbox = $Hitbox
@onready var visuals: Node2D = $Visuals

var current_hp: float
var is_hit_frozen: bool = false ## 是否处于受击顿帧
var original_speed: float

## 屏幕检测相关
var has_entered_screen: bool = false  ## 是否曾经进入过屏幕
var is_offscreen: bool = false        ## 当前是否在屏幕外
var offscreen_timer: float = 0.0      ## 离开屏幕后的计时器
const OFFSCREEN_DESTROY_TIME: float = 5.0  ## 离开屏幕后销毁时间

## 血条组件
var hp_bar: ProgressBar
var hp_bar_bg: ColorRect
var hp_label: Label
var screen_notifier: VisibleOnScreenNotifier2D

func _ready() -> void:
	current_hp = max_hp
	original_speed = speed
	add_to_group("enemies")

	if hitbox:
		hitbox.damage = contact_damage

	if hurtbox:
		hurtbox.hurt.connect(_on_hurtbox_hurt)

	# 屏幕可见性检测
	screen_notifier = VisibleOnScreenNotifier2D.new()
	screen_notifier.rect = Rect2(-50, -50, 100, 100)
	add_child(screen_notifier)
	screen_notifier.screen_entered.connect(_on_screen_entered)
	screen_notifier.screen_exited.connect(_on_screen_exited)

	# 创建血条
	_create_hp_bar()

func _physics_process(delta: float) -> void:
	if is_hit_frozen:
		return
	position.x -= speed * delta

	# 屏幕外销毁计时
	_update_offscreen_timer(delta)

## 创建血条
func _create_hp_bar() -> void:
	# 血条容器
	var container = Node2D.new()
	container.name = "HPBarContainer"
	add_child(container)
	container.position = Vector2(0, -60)  # 在敌人上方

	# 血条背景 (暗色)
	hp_bar_bg = ColorRect.new()
	hp_bar_bg.size = hp_size
	hp_bar_bg.position = Vector2(-30, 0)
	hp_bar_bg.color = Color(0.2, 0.2, 0.2, 0.8)
	container.add_child(hp_bar_bg)

	# 血条前景
	hp_bar = ProgressBar.new()
	hp_bar.size = hp_size
	hp_bar.position = Vector2(-30, 0)
	hp_bar.max_value = max_hp
	hp_bar.value = current_hp
	hp_bar.show_percentage = false

	# 自定义样式
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.0, 1.0, 0.5, 1.0)  # 霓虹绿
	style.set_corner_radius_all(2)
	style.content_margin_left = 2.0
	style.content_margin_right = 2.0

	hp_bar.add_theme_stylebox_override("fill", style)
	# 移除边框让样式更干净
	hp_bar.add_theme_constant_override("border", 0)

	container.add_child(hp_bar)

	# 添加数值标签
	hp_label = Label.new()
	hp_label.name = "HPBarLabel"
	hp_label.text = str(int(current_hp)) + "/" + str(int(max_hp))
	hp_label.add_theme_font_size_override("font_size", 18)
	hp_label.add_theme_color_override("font_color", Color.WHITE)
	hp_label.add_theme_color_override("outline_color", Color.BLACK)
	hp_label.add_theme_constant_override("outline_size", 2)
	hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	# 居中显示在血条上方
	hp_label.position = Vector2(-30, -20) # 调整位置到血条上方
	hp_label.size = Vector2(60, 20)
	container.add_child(hp_label)

## 更新血条显示
func _update_hp_bar() -> void:
	if hp_bar:
		hp_bar.value = current_hp
		# 血量低于30%变红
		if current_hp / max_hp < 0.3:
			var style = hp_bar.get_theme_stylebox("fill")
			if style:
				style.bg_color = Color(1.0, 0.2, 0.2, 1.0)  # 红色

	# 更新数值文本
	if hp_label:
		hp_label.text = str(int(current_hp))

## 受击回调函数
func _on_hurtbox_hurt(attacker_hitbox: Hitbox) -> void:
	var damage_amount = attacker_hitbox.damage
	var hitbox_knockback = attacker_hitbox.knockback
	var knockback_dir = (global_position - attacker_hitbox.global_position).normalized()
	take_damage(damage_amount, knockback_dir, hitbox_knockback)

# --- 扣血逻辑 ---
func take_damage(amount: float, knockback_dir: Vector2 = Vector2.RIGHT, knockback_amount: float = -1.0) -> void:
	current_hp -= amount

	# 更新血条
	_update_hp_bar()

	# 使用传入的击退值，如果为-1则使用默认值
	var actual_knockback = knockback_amount if knockback_amount >= 0 else knockback_strength

	# 触发受击效果
	trigger_hit_effects(knockback_dir, actual_knockback)

	if current_hp <= 0:
		die()

## 触发所有受击效果
func trigger_hit_effects(knockback_dir: Vector2, knockback_amount: float) -> void:
	flash_hit_effect()
	apply_knockback(knockback_dir, knockback_amount)
	apply_hit_freeze()

## 受击闪烁效果
func flash_hit_effect() -> void:
	if not visuals:
		return

	var tween = create_tween()
	# 闪烁为霓虹青色
	visuals.modulate = hit_flash_color
	tween.tween_property(visuals, "modulate", hit_flash_recover_color, hit_flash_duration).set_ease(Tween.EASE_OUT)

## 击退效果（仅水平方向）
func apply_knockback(direction: Vector2, knockback_amount: float) -> void:
	var tween = create_tween()
	# 只保留水平方向的击退，忽略垂直分量
	var horizontal_dir = Vector2(sign(direction.x) if direction.x != 0 else 1.0, 0)
	var knockback_offset = horizontal_dir * knockback_amount
	var target_pos = position + knockback_offset
	tween.tween_property(self, "position", target_pos, 0.1).set_ease(Tween.EASE_OUT)

## 受击顿帧
func apply_hit_freeze() -> void:
	if hit_freeze_duration <= 0:
		return

	is_hit_frozen = true
	get_tree().create_timer(hit_freeze_duration).timeout.connect(_end_hit_freeze)

func _end_hit_freeze() -> void:
	is_hit_frozen = false

## 进入屏幕回调
func _on_screen_entered() -> void:
	has_entered_screen = true
	is_offscreen = false
	offscreen_timer = 0.0

## 离开屏幕回调
func _on_screen_exited() -> void:
	is_offscreen = true

## 更新屏幕外计时器
func _update_offscreen_timer(delta: float) -> void:
	if not has_entered_screen:
		# 还没进入过屏幕，不计时
		return

	if is_offscreen:
		offscreen_timer += delta
		if offscreen_timer >= OFFSCREEN_DESTROY_TIME:
			queue_free()
	else:
		offscreen_timer = 0.0

## 死亡处理
func die() -> void:
	# 清理血条
	var hp_container = get_node_or_null("HPBarContainer")
	if hp_container:
		hp_container.queue_free()

	# 掉落经验
	call_deferred("_drop_experience")

	# 掉落金币
	call_deferred("_drop_coins")

	spawn_death_particles()
	queue_free()

## 掉落经验
func _drop_experience() -> void:
	var exp_orb_scene = load("res://scene/pickup/exp_orb.tscn")
	if not exp_orb_scene:
		return

	var drop_count = 0

	if is_elite:
		# 精英怪：根据关卡掉落多个经验球
		var current_level = Global.current_level
		var min_drop = 1 + current_level / 3  # 最少1个，每3关+1
		var max_drop = 2 + current_level / 2  # 最多2个，每2关+1
		drop_count = randi_range(min_drop, max_drop)
	else:
		# 普通怪：有概率掉落0-1个
		if randf() < exp_drop_chance:
			drop_count = 1

	# 生成经验球
	for i in range(drop_count):
		var exp_orb = exp_orb_scene.instantiate()
		exp_orb.global_position = global_position
		get_tree().current_scene.add_child(exp_orb)

## 掉落金币
func _drop_coins() -> void:
	var coin_scene = load("res://scene/pickup/coin_pickup.tscn")
	if not coin_scene:
		return

	var drop_count = 0

	if is_elite:
		# 精英怪：根据关卡掉落多个金币
		var level = Global.current_level
		var min_drop = 2 + level / 2  # 最少2个，每2关+1
		var max_drop = 4 + level      # 最多4个，每关+1
		drop_count = randi_range(min_drop, max_drop)
	else:
		# 普通怪：有概率掉落0-1个
		if randf() < coin_drop_chance:
			drop_count = 1

	# 生成金币
	for i in range(drop_count):
		var coin = coin_scene.instantiate()
		coin.global_position = global_position
		get_tree().current_scene.add_child(coin)

## 生成死亡粒子
func spawn_death_particles() -> void:
	# 创建独立的粒子节点（不随敌人销毁）
	var particles = CPUParticles2D.new()
	particles.emitting = false
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.amount = death_particle_amount
	particles.lifetime = death_particle_lifetime

	# 粒子外观
	particles.modulate = death_particle_color
	particles.scale_amount_min = death_particle_scale_min
	particles.scale_amount_max = death_particle_scale_max

	# 粒子由大到小消散
	var curve = Curve.new()
	curve.add_point(Vector2(0.0, 1.0))
	curve.add_point(Vector2(0.5, 0.6))
	curve.add_point(Vector2(1.0, 0.0))
	particles.scale_amount_curve = curve

	# 粒子运动 - 向外爆炸
	particles.direction = Vector2.ZERO
	particles.spread = 180.0
	particles.initial_velocity_min = death_particle_velocity_min
	particles.initial_velocity_max = death_particle_velocity_max
	particles.gravity = Vector2.ZERO
	particles.damping_min = 150.0
	particles.damping_max = 250.0

	# 添加到场景根节点（不随敌人销毁）
	get_tree().current_scene.add_child(particles)
	particles.global_position = global_position
	particles.restart()
	particles.emitting = true

	# 自动清理
	get_tree().create_timer(2.0).timeout.connect(particles.queue_free)
