extends TraceObject

const MARK = preload("res://mark.tscn")

enum TORPEDO_MODE {TURN, STRAIGHT, ZIGZAG}

var target_position: Vector2
var target_velocity: Vector2
var target_course: float
var max_rotation_deg: float = 2
var target_bearing: float

var turn_to_left: bool = true
var mode: TORPEDO_MODE = TORPEDO_MODE.TURN
var atack_from_left_board: bool
var to_zigzag_course: float


func _ready() -> void:
	if global_position.distance_to(target_position) > speed * life_time:
		get_parent().out_of_range()
		return
	#первичный рассчет
	var intercept_point: Vector2 = find_intercept_point(target_velocity, target_position, global_position)
	var course_delta: float = 0
	var new_course:float
	if intercept_point != Vector2.INF:
		new_course = rad_to_deg(global_position.angle_to_point(intercept_point)) + 90
		course_delta = new_course - course
		if course_delta < -180:
			course_delta += 360
	else:
		get_parent().out_of_range()
		return
	if abs(course_delta) > 35:
		get_parent().out_of_range()
	else:
		if course_delta >= 0: 
			turn_to_left = false
		else:
			turn_to_left = true
		$TurnTimer.wait_time = abs(course_delta) / max_rotation_deg * \
			(1 + abs(course_delta) / max_rotation_deg * 15 / global_position.distance_to(target_position))
		$TurnTimer.start()

		$StraightTimer.wait_time = global_position.distance_to(intercept_point) / speed - $TurnTimer.wait_time

		atack_from_left_board = is_atack_from_left_board()
		if atack_from_left_board:
			to_zigzag_course = TraceObject.course_to_360(target_course + 90)
		else:
			to_zigzag_course = TraceObject.course_to_360(target_course - 90)
		if turn_to_left:
			course_delta = to_zigzag_course - course + $TurnTimer.wait_time * max_rotation_deg
		else:
			course_delta = to_zigzag_course - course - $TurnTimer.wait_time * max_rotation_deg
		if course_delta < -180:
			course_delta += 360
		if atack_from_left_board:
			$ZigzagTimer.wait_time = (180 - course_delta) / max_rotation_deg
		else:
			$ZigzagTimer.wait_time = (180 + course_delta) / max_rotation_deg


#как решать проблему, когда скорость цели больше скорости торпеды?
#расходится результат с find_intercept_point() потому что bearing с лодки, а не торпеды
func get_torpedo_course() -> float: 
	var vg: float = target_velocity.length()
	var beta: float = asin(vg / speed * sin(deg_to_rad(course - 180 - target_course)))
	return target_bearing + rad_to_deg(beta)


func move(delta: float):
	super.move(delta)
	
	match mode:
		TORPEDO_MODE.TURN, TORPEDO_MODE.ZIGZAG:
			if turn_to_left:
				course -= max_rotation_deg * delta
			else:
				course += max_rotation_deg * delta
		TORPEDO_MODE.STRAIGHT:
			pass


func find_intercept_point(_target_velocity: Vector2, _target_position: Vector2, _position: Vector2) -> Vector2:
	#printt(_position, _target_position, _target_velocity)
	var target_vel_x := _target_velocity.x; var target_vel_y := _target_velocity.y
	var target_pos_x := _target_position.x; var target_pos_y := _target_position.y
	var turret_pos_x := _position.x; var turret_pos_y := _position.y
	#вычисление дискриминанта
	var a: float = ((target_vel_x * target_vel_x) + (target_vel_y * target_vel_y) - (speed * speed))
	var b: float = 2 * (target_vel_x * (target_pos_x - turret_pos_x) + target_vel_y * (target_pos_y - turret_pos_y))
	var c: float = (((target_pos_x - turret_pos_x) * (target_pos_x - turret_pos_x)) + ((target_pos_y - turret_pos_y) * (target_pos_y - turret_pos_y)))
	var disc: float = b * b - (4 * a * c)
	if disc < 0: return Vector2.INF #цель не поразить
	var t: float = (-b - sqrt(disc)) / (2 * a)
	if t <= 0: return Vector2.INF #цель не поразить
	return _target_position + _target_velocity * t


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


func _on_turn_timer_timeout() -> void:
	mode = TORPEDO_MODE.STRAIGHT
	$StraightTimer.start()


func _on_straight_timer_timeout() -> void:
	mode = TORPEDO_MODE.ZIGZAG
	turn_to_left = atack_from_left_board
	$ZigzagTimer.start()


func _on_area_2d_area_entered(_area: Area2D) -> void:
	var mark = MARK.instantiate()
	mark.global_position = $Area2D.global_position
	get_parent().add_child(mark)


func _on_zigzag_timer_timeout() -> void:
	$ZigzagTimer.wait_time = 180 / max_rotation_deg
	$ZigzagTimer.start()
	turn_to_left = not turn_to_left
