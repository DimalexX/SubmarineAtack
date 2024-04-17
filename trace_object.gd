extends Sprite2D
class_name TraceObject

@export_range(0, 359.999, 0.001) var course: float = 90: #0-360 градусов, 0 - на север (вверх)
	set(new_value):
		course = TraceObject.course_to_360(new_value)
@export var speed: float = 20 #метров в секунду
@export var life_time: float = 100000 #секунд
@export_color_no_alpha var trace_color: Color = Color.WHITE
const PIXEL = preload("res://pixel.tscn")


static func course_to_360(new_value: float) -> float:
	new_value = fmod(new_value, 360)
	if new_value < 0: new_value += 360
	return new_value


func _physics_process(delta: float) -> void:
	life_time -= delta
	if life_time <= 0:
		get_parent().started = false
		queue_free()
	else:
		move(delta)


func move(delta: float):
	rotation = course_to_rotation(course)
	global_position += Vector2(speed*delta, 0).rotated(rotation)


func course_to_rotation(_course: float) -> float:
	return deg_to_rad(_course-90)


func _on_trace_timer_timeout() -> void:
	var p = PIXEL.instantiate()
	p.global_position = global_position
	p.modulate = trace_color
	get_parent().add_child(p)
