extends Node2D

const SUBMARINE = preload("res://submarine.tscn")
const TANKER = preload("res://tanker.tscn")
const TORPEDO = preload("res://torpedo.tscn")
const MECHANICAL_TORPEDO = preload("res://mechanical_torpedo.tscn")

var submarine: TraceObject
var tanker: TraceObject
var torpedo: TraceObject
var started: bool = false
var zoom_const: float = 200

@onready var camera_2d: Camera2D = $Camera2D


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("zoom_in"):
		zoom_const += 50
		update_camera_zoom()
	if Input.is_action_just_pressed("zoom_out"):
		zoom_const -= 50
		if zoom_const < 50:
			zoom_const = 50
		update_camera_zoom()
	if started:
		camera_2d.position.x = (min(submarine.position.x, tanker.position.x, torpedo.position.x) + \
			max(submarine.position.x, tanker.position.x, torpedo.position.x)) / 2 - 200
		camera_2d.position.y = (min(submarine.position.y, tanker.position.y, torpedo.position.y) + \
			max(submarine.position.y, tanker.position.y, torpedo.position.y)) / 2


func update_camera_zoom() -> void:
	camera_2d.zoom.x = zoom_const / 1000
	camera_2d.zoom.y = zoom_const / 1000


func _on_button_pressed() -> void:
	Engine.time_scale = clampf(float(%TimeScale.text), 1, 10)
	%TimeScale.text = str(Engine.time_scale)
	started = true
	
	submarine = SUBMARINE.instantiate()
	submarine.course = float(%SubmarineCourse.text)
	%SubmarineCourse.text = str(submarine.course)
	add_child(submarine)
	
	tanker = TANKER.instantiate()
	tanker.course = float(%TargetCourse.text)
	%TargetCourse.text = str(tanker.course)
	tanker.speed = clampf(float(%TargetSpeed.text), 0, 15)
	%TargetSpeed.text = str(tanker.speed)
	var t_distance: float = clampf(float(%TargetDistance.text), 300, 10000)
	%TargetDistance.text = str(t_distance)
	var bearing: float = TraceObject.course_to_360(float(%TargetBearing.text))
	%TargetBearing.text = str(bearing)
	tanker.global_position = submarine.global_position + Vector2(t_distance, 0).rotated(deg_to_rad(bearing-90))
	add_child(tanker)
	
	if %TorpedoType.selected == 1:
		torpedo = TORPEDO.instantiate()
	else:
		torpedo = MECHANICAL_TORPEDO.instantiate()
		torpedo.target_bearing = bearing
	torpedo.life_time = float(%TorpedoLifeTime.text)
	torpedo.course = submarine.course
	torpedo.speed = clampf(float(%TorpedoSpeed.text), 15, 25)
	%TorpedoSpeed.text = str(torpedo.speed)
	torpedo.max_rotation_deg = clampf(float(%TorpedoRotation.text), 1, 5)
	%TorpedoRotation.text = str(torpedo.max_rotation_deg)
	torpedo.target_velocity = Vector2(tanker.speed, 0).rotated(deg_to_rad(tanker.course-90))
	torpedo.target_course = tanker.course
	torpedo.target_position = tanker.global_position
	torpedo.global_position = submarine.global_position + Vector2(35, 0).rotated(deg_to_rad(torpedo.course-90))
	add_child(torpedo)
	
	var target_random = clampf(float(%TargetRandom.text), 0, 20)
	%TargetRandom.text = str(target_random)
	tanker.course += randf_range(-target_random, target_random)
	tanker.speed += randf_range(-tanker.speed * target_random / 100, tanker.speed * target_random / 100)


func out_of_range() -> void:
	print("Цель не поразить!")
	%Warning.show()
	%WarningTimer.wait_time = 5 * Engine.time_scale
	%WarningTimer.start()
	started = false
	torpedo.queue_free()
	submarine.queue_free()
	tanker.queue_free()


func _on_warning_timer_timeout() -> void:
	%Warning.hide()


func _on_check_button_toggled(_toggled_on: bool) -> void:
	$AudioStreamPlayer.stream_paused = not $AudioStreamPlayer.stream_paused
