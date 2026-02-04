extends CanvasLayer

## 玩家HUD - 显示血量、金币、等级、经验等信息

@onready var hp_bar: ProgressBar = $TopLeft/HPContainer/HPBarContainer/HPBar
@onready var hp_label: Label = $TopLeft/HPContainer/HPBarContainer/HPLabel
@onready var hp_bar_glow: ProgressBar = $TopLeft/HPContainer/HPBarContainer/HPBarGlow
@onready var gold_label: Label = $TopLeft/GoldContainer/GoldLabel
@onready var level_label: Label = $TopLeft/LevelContainer/LevelLabel
@onready var exp_label: Label = $TopLeft/ExpContainer/ExpLabel

func _ready() -> void:
	# 连接全局信号
	Global.player_hp_changed.connect(_on_player_hp_changed)
	Global.player_died.connect(_on_player_died)
	Global.gold_changed.connect(_on_gold_changed)
	Global.experience_changed.connect(_on_experience_changed)

	# 初始化显示
	_update_hp_display(Global.player_current_hp, Global.player_max_hp)
	_update_gold_display(Global.gold)
	_update_exp_display(Global.experience, Global.get_exp_to_next_level(), Global.player_level)

func _on_player_hp_changed(current_hp: float, max_hp: float) -> void:
	_update_hp_display(current_hp, max_hp)

func _update_hp_display(current_hp: float, max_hp: float) -> void:
	if hp_bar:
		hp_bar.max_value = max_hp
		hp_bar.value = current_hp

	if hp_bar_glow:
		hp_bar_glow.max_value = max_hp
		hp_bar_glow.value = current_hp

	if hp_label:
		hp_label.text = "%d / %d" % [int(current_hp), int(max_hp)]

	# 血量低于30%时变红
	if max_hp > 0 and current_hp / max_hp < 0.3:
		_set_hp_bar_color(Color(1.0, 0.2, 0.2, 1.0), Color(2.0, 0.3, 0.3, 0.5))
	else:
		_set_hp_bar_color(Color(0.0, 1.0, 0.8, 1.0), Color(0.0, 2.0, 1.5, 0.5))

func _set_hp_bar_color(bar_color: Color, glow_color: Color) -> void:
	if hp_bar:
		var style = hp_bar.get_theme_stylebox("fill") as StyleBoxFlat
		if style:
			style.bg_color = bar_color

	if hp_bar_glow:
		var glow_style = hp_bar_glow.get_theme_stylebox("fill") as StyleBoxFlat
		if glow_style:
			glow_style.bg_color = glow_color

func _on_player_died() -> void:
	# 玩家死亡时的UI反馈
	if hp_label:
		hp_label.text = "DEAD"
		hp_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2, 1.0))

func _on_gold_changed(amount: int) -> void:
	_update_gold_display(amount)

func _update_gold_display(amount: int) -> void:
	if gold_label:
		gold_label.text = str(amount)

func _on_experience_changed(current_exp: int, exp_to_next: int, player_level: int) -> void:
	_update_exp_display(current_exp, exp_to_next, player_level)

func _update_exp_display(current_exp: int, exp_to_next: int, player_level: int) -> void:
	if level_label:
		level_label.text = "Lv.%d" % player_level

	if exp_label:
		exp_label.text = "%d / %d" % [current_exp, exp_to_next]
