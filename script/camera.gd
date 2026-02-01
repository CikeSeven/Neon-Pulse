extends Camera2D

## 屏幕震动相机脚本

var shake_intensity: float = 0.0
var shake_duration: float = 0.0
var shake_timer: float = 0.0
var original_offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	Global.camera_ref = self
	Global.screen_shake_requested.connect(_on_screen_shake_requested)
	original_offset = offset

func _process(delta: float) -> void:
	if shake_timer > 0:
		shake_timer -= delta

		# 计算衰减
		var decay = shake_timer / shake_duration
		var current_intensity = shake_intensity * decay

		# 随机偏移
		offset = original_offset + Vector2(
			randf_range(-current_intensity, current_intensity),
			randf_range(-current_intensity, current_intensity)
		)

		# 震动结束
		if shake_timer <= 0:
			offset = original_offset

func _on_screen_shake_requested(intensity: float, duration: float) -> void:
	# 如果新的震动更强，则覆盖
	if intensity > shake_intensity or shake_timer <= 0:
		shake_intensity = intensity
		shake_duration = duration
		shake_timer = duration

## 手动触发震动
func shake(intensity: float = 10.0, duration: float = 0.3) -> void:
	_on_screen_shake_requested(intensity, duration)

func _exit_tree() -> void:
	Global.camera_ref = null
