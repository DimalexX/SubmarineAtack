extends TraceObject

const MARK = preload("res://mark.tscn")

var target_position: Vector2
var target_velocity: Vector2
var target_course: float
var max_rotation_deg: float = 2

var atack_from_left_board: bool
var zigzag_mode: bool = false
var zigzag_first_turn: bool = true


func move(delta: float):
	super.move(delta)
	
	target_position += target_velocity * delta
	rotate_to_target(delta)


func rotate_to_target(delta: float):
	if zigzag_mode:
		if atack_from_left_board:
			course += max_rotation_deg * delta
			return
		else:
			course -= max_rotation_deg * delta
			return

	var intercept_point = find_intercept_point()
	if intercept_point != Vector2.INF:
		var new_course = rad_to_deg(global_position.angle_to_point(intercept_point)) + 90
		if new_course < 0: new_course += 360
		if abs(new_course - course) > 90: #прошли контакт
			atack_from_left_board = is_atack_from_left_board()
			%ZigzagTimer.wait_time = 20 / max_rotation_deg
			%ZigzagTimer.start()
			zigzag_mode = true
		else:
			course = move_toward(course, new_course, max_rotation_deg * delta)
	else:
		print("Цель не поразить!")


func is_atack_from_left_board() -> bool:
	if target_course >= 0 and target_course <= 180:
		if course >= target_course and course <= target_course + 180:
			return true
		else:
			return false
	else:
		if course <= target_course and course > target_course - 180:
			return false
		else:
			return true


#Вычисление точки упреждение для поражения цели (CharacterBody2D) снарядом
#со скоростью BULLET_SPEED. Возвращает координаты точки, если возможно поразить
func find_intercept_point() -> Vector2:
	var target_vel_x := target_velocity.x; var target_vel_y := target_velocity.y
	var target_pos_x := target_position.x; var target_pos_y := target_position.y
	var turret_pos_x := global_position.x; var turret_pos_y := global_position.y
	#вычисление дискриминанта
	var a: float = ((target_vel_x * target_vel_x) + (target_vel_y * target_vel_y) - (speed * speed))
	var b: float = 2 * (target_vel_x * (target_pos_x - turret_pos_x) + target_vel_y * (target_pos_y - turret_pos_y))
	var c: float = (((target_pos_x - turret_pos_x) * (target_pos_x - turret_pos_x)) + ((target_pos_y - turret_pos_y) * (target_pos_y - turret_pos_y)))
	var disc: float = b * b - (4 * a * c)
	if disc < 0: return Vector2.INF #цель не поразить
	var t: float = (-b - sqrt(disc)) / (2 * a)
	if t <= 0: return Vector2.INF #цель не поразить
	return target_position + target_velocity * t


func _on_zigzag_timer_timeout() -> void:
	if zigzag_first_turn:
		atack_from_left_board = not atack_from_left_board
		%ZigzagTimer.wait_time = 180 / max_rotation_deg
		%ZigzagTimer.start()
	else:
		zigzag_mode = false
	zigzag_first_turn = not zigzag_first_turn


func _on_area_2d_area_entered(_area: Area2D) -> void:
	var mark = MARK.instantiate()
	mark.global_position = $Area2D.global_position
	get_parent().add_child(mark)
