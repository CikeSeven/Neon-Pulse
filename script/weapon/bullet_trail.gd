extends Line2D

@export var pointCount: int = 10
@export var isSpawn: bool = true

func _physics_process(_delta: float) -> void:

	if isSpawn:
		if get_point_count() > pointCount:
			remove_point(0)
		drawPoint()
	else:
		if get_point_count() > 0:
			remove_point(0)

func drawPoint() -> void:
	add_point(owner.global_position)
