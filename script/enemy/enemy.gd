class_name Enemy extends Node2D


@export var speed: float = 150
@export var max_hp: float = 30.0
@export var contact_damage: float = 10.0 # 敌人撞玩家造成的伤害

# --- 节点引用 ---
# 确保你的场景里节点名字是 Hurtbox 和 Hitbox
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var hitbox: Hitbox = $Hitbox
@onready var visuals: Node2D = $Visuals

var current_hp: float

func _ready() -> void:
	current_hp = max_hp
	add_to_group("enemies")

	if hitbox:
		hitbox.damage = contact_damage
	
	if hurtbox:
		hurtbox.hurt.connect(_on_hurtbox_hurt)
	
	# 自动销毁逻辑
	var notifier = VisibleOnScreenNotifier2D.new()
	notifier.rect = Rect2(-20, -20, 40, 40)
	add_child(notifier)
	notifier.screen_exited.connect(queue_free)

func _physics_process(delta: float) -> void:
	position.x -= speed * delta

## 受击回调函数
func _on_hurtbox_hurt(attacker_hitbox: Hitbox) -> void:
	var damage_amount = attacker_hitbox.damage
	take_damage(damage_amount)

# --- 扣血逻辑 ---
func take_damage(amount: float) -> void:
	current_hp -= amount
	print("%s took %s damage. HP: %s" % [name, amount, current_hp])
	flash_hit_effect()
	
	if current_hp <= 0:
		die()

func die() -> void:
	queue_free()

##受击特效
func flash_hit_effect() -> void:
	if visuals:
		var tween = create_tween()
		visuals.modulate = Color(5, 5, 5)
		tween.tween_property(visuals, "modulate", Color.WHITE, 0.12)
