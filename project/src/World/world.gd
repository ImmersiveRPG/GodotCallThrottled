# Copyright (c) 2023 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
# This file is licensed under the MIT License
# https://github.com/ImmersiveRPG/GodotCallThrottled

extends Node3D

const _ball_scene : PackedScene = preload("res://src/Ball/ball.tscn")

@onready var _ball_holder : Node = $BallHolder
var _is_artificial_delay := false

func _ready() -> void:
	var frame_budget_msec := floori(1000 / float(Engine.get_physics_ticks_per_second()))
	var frame_budget_threshold_msec := 5
	GodotCallThrottled.start(frame_budget_msec, frame_budget_threshold_msec)
	GodotCallThrottled.connect("waiting_count_change", Callable(self, "_on_waiting_count_change"))

func _on_waiting_count_change(waiting_count : int) -> void:
	var label = $LabelWaitingCount
	label.text = "Waiting calls: %s" % [waiting_count]

func _process(_delta : float) -> void:
	if Global._is_logging: print("    world _process: %s" % [Time.get_ticks_msec()])

func _physics_process(_delta : float) -> void:
	if Global._is_logging: print("    world _physics_process: %s" % [Time.get_ticks_msec()])
	if _is_artificial_delay: OS.delay_msec(7)

func _on_fps_timer_timeout() -> void:
	var fps := Engine.get_frames_per_second()
	var count := _ball_holder.get_child_count()
	var title := "FPS: %s, Balls: %s" % [fps, count]
	self.get_window().set_title(title)

func _on_button_spawn_balls_pressed() -> void:
	var before := Time.get_ticks_msec()

	for n in 500:
		# Add ball
		var ball := _ball_scene.instantiate()
		_ball_holder.add_child(ball)

		# Give ball random position around center
		const r := 25.0
		ball.transform.origin = Vector3(
			randf_range(-r, r),
			3.0,
			randf_range(-r, r),
		)

	var after := Time.get_ticks_msec()
	var used := after - before
	print("Blocked for msecs: %s" % [used])

func _on_button_spawn_balls_deferred_pressed() -> void:
	#print("        button: %s, frame: %s" % [Time.get_ticks_msec(), self.get_tree().get_frame()])
	var cb_defer := func():
		#print("        cb_defer: %s, frame: %s" % [Time.get_ticks_msec(), self.get_tree().get_frame()])
		# Add ball
		var ball := _ball_scene.instantiate()
		_ball_holder.add_child(ball)

		# Give ball random position around center
		const r := 25.0
		ball.transform.origin = Vector3(
			randf_range(-r, r),
			3.0,
			randf_range(-r, r),
		)

	for n in 500:
		cb_defer.call_deferred()

	#print("        button end: %s, frame: %s" % [Time.get_ticks_msec(), self.get_tree().get_frame()])

func _on_button_spawn_balls_throttled_pressed() -> void:
	var cb := func():
		# Add ball
		var ball := _ball_scene.instantiate()
		_ball_holder.add_child(ball)

		# Give ball random position around center
		const r := 25.0
		ball.transform.origin = Vector3(
			randf_range(-r, r),
			3.0,
			randf_range(-r, r),
		)

	for n in 500:
		GodotCallThrottled.call_throttled(cb)



func _on_button_remove_all_balls_pressed() -> void:
	for ball in _ball_holder.get_children():
		ball.queue_free()


func _on_check_box_artificial_delay_pressed() -> void:
	_is_artificial_delay = not _is_artificial_delay
