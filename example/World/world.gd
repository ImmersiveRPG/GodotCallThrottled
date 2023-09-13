# Copyright (c) 2023 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
# This file is licensed under the MIT License
# https://github.com/ImmersiveRPG/GodotCallThrottled

extends Node3D

const _ball_scene : PackedScene = preload("res://example/Ball/ball.tscn")

@onready var _ball_holder : Node = $BallHolder

@onready var _is_logging : bool = $CheckBoxLog.button_pressed
@onready var _is_artificial_delay : bool = $CheckBoxArtificialDelay.button_pressed
@onready var _is_remove_balls_when_over_frame_budget : bool = $CheckBoxRemove100.button_pressed
@onready var _is_remove_all_balls : bool = $CheckBoxRemoveAll.button_pressed

func _ready() -> void:
	# Wait 1 second for the game engine to settle down
	await self.get_tree().create_timer(1).timeout

	# Setup GodotCallThrottled and callbacks
	var frame_budget_usec := floori(1000000 / float(Engine.get_physics_ticks_per_second()))
	var frame_budget_threshold_usec := 5000
	CallThrottled.start(frame_budget_usec, frame_budget_threshold_usec)

	CallThrottled.connect("log", Callable(self, "_on_log"))
	CallThrottled.connect("waiting_count_change", Callable(self, "_on_waiting_count_change"))
	CallThrottled.connect("engine_not_busy", Callable(self, "_on_engine_not_busy"))
	CallThrottled.connect("engine_too_busy", Callable(self, "_on_engine_too_busy"))
	CallThrottled.connect("over_frame_budget", Callable(self, "_on_over_frame_budget"))

func _on_log(frame_budget_usec : int, overhead_usec : int, frame_budget_expenditure_usec : int, frame_budget_surplus_usec : int, call_count : int, waiting_count : int) -> void:
	if not _is_logging: return
	print("budget_usec:%s, overhead_usec:%s, expenditure_usec:%s, surplus_usec:%s, called:%s, waiting:%s" % [frame_budget_usec, overhead_usec, frame_budget_expenditure_usec, frame_budget_surplus_usec, call_count, waiting_count])

func _on_waiting_count_change(waiting_count : int) -> void:
	var label = $LabelWaitingCount
	label.text = "Waiting calls: %s" % [waiting_count]

func _on_engine_not_busy(waiting_count : int) -> void:
	#print("+++ Called _on_engine_not_busy waiting_count: %s" % [waiting_count])
	$LabelBusy.hide()

func _on_engine_too_busy(waiting_count : int) -> void:
	#print("--- Called _on_engine_too_busy waiting_count: %s" % [waiting_count])
	$LabelBusy.show()

	# We are continuously over frame budget, so free all the balls
	if _is_remove_all_balls:
		for child in _ball_holder.get_children():
			child.queue_free()

func _on_over_frame_budget(used_usec : int, budget_usec : int) -> void:
	if not _is_remove_balls_when_over_frame_budget: return

	print("Called _on_over_frame_budget used_usec: %s, budget_usec: %s" % [used_usec, budget_usec])

	# The current frame went over budget, so free 100 balls
	var i := 0
	for child in _ball_holder.get_children():
		child.queue_free()
		i += 1
		if i > 100:
			return

func _process(_delta : float) -> void:
	pass

func _physics_process(_delta : float) -> void:
	if _is_artificial_delay: OS.delay_usec(7000)

func _on_fps_timer_timeout() -> void:
	var fps := Engine.get_frames_per_second()
	var count := _ball_holder.get_child_count()
	#var title := "Balls: %s" % [count]
	#self.get_window().set_title(title)
	$LabelFPS.text = "FPS: %s" % [fps]
	$LabelBalls.text = "Balls: %s" % [count]

func _on_button_spawn_balls_pressed() -> void:
	var before := Time.get_ticks_usec()

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

	var after := Time.get_ticks_usec()
	var used := after - before
	print("Blocked for usecs: %s" % [used])

func _on_button_spawn_balls_deferred_pressed() -> void:
	#print("        button: %s, frame: %s" % [Time.get_ticks_usec(), self.get_tree().get_frame()])
	var cb_defer := func():
		#print("        cb_defer: %s, frame: %s" % [Time.get_ticks_usec(), self.get_tree().get_frame()])
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

	#print("        button end: %s, frame: %s" % [Time.get_ticks_usec(), self.get_tree().get_frame()])

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
		CallThrottled.call_throttled(cb)



func _on_button_remove_all_balls_pressed() -> void:
	for ball in _ball_holder.get_children():
		ball.queue_free()


func _on_check_box_artificial_delay_pressed() -> void:
	_is_artificial_delay = not _is_artificial_delay

func _on_check_box_remove_100_pressed() -> void:
	_is_remove_balls_when_over_frame_budget = not _is_remove_balls_when_over_frame_budget



func _on_check_box_remove_all_pressed() -> void:
	_is_remove_all_balls = not _is_remove_all_balls


func _on_check_box_log_pressed() -> void:
	_is_logging = not _is_logging
