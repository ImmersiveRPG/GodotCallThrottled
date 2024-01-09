# Copyright (c) 2023 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
# This file is licensed under the MIT License
# https://github.com/ImmersiveRPG/GodotCallThrottled

extends Node

const INT32_MAX := int(int(pow(2, 31)) - 1)
const INT64_MAX := int(int(pow(2, 63)) - 1)

signal log(frame_budget_usec : int, overhead_usec : int, frame_budget_expenditure_usec : int, frame_budget_surplus_usec : int, call_count : int, waiting_count : int)
signal waiting_count_change(waiting_count : int)
signal over_frame_budget(used_usec : int, budget_usec : int)
signal engine_too_busy(waiting_count : int)
signal engine_not_busy(waiting_count : int)

var _main_iteration_start_ticks := 0
var _main_iteration_end_ticks := 0
var _last_node_scene := preload("res://addons/GodotCallThrottled/LastNode/last_node.tscn")
var _last_node : Node = null

var _to_call : Array[Dictionary] = []
var _mutex := Mutex.new()

const _is_logging := false
var _frame_budget_usec := 0
var _frame_budget_threshold_usec := 0
var _is_setup := false
var _was_working := false
var _is_too_busy_to_work := false
var _fn_get_frame_start_ticks_usec : Callable
var _prev_waiting_count := -1

func _on_start_physics_frame() -> void:
	#if _is_logging: print("Frame: %s" % [self.get_tree().get_frame()])
	self._main_iteration_start()

	# Just return if there isn't a scene yet
	var target := self.get_tree().root
	if not target: return

	# Forget last node if it has been freed
	if not is_instance_valid(_last_node):
		_last_node = null

	# Create the dummy last node in tree
	if not _last_node:
		_last_node = _last_node_scene.instantiate()
		target.add_child(_last_node)

	# Move last node to be last in tree
	if _last_node and _last_node.get_index() != target.get_child_count()-1:
		target.move_child(_last_node, target.get_child_count()-1)

func _main_iteration_start() -> void:
	_main_iteration_start_ticks = _fn_get_frame_start_ticks_usec.call()
	_main_iteration_end_ticks = _main_iteration_start_ticks
	#if _is_logging: print("    _main_iteration_start: %s" % [_main_iteration_start_ticks])

func _main_iteration_done() -> void:
	_main_iteration_end_ticks = Time.get_ticks_usec()
	#if _is_logging: print("    _main_iteration_done: %s" % [_main_iteration_end_ticks])
	var overhead_usec := clampi(_main_iteration_end_ticks - _main_iteration_start_ticks, 0, INT64_MAX)
	#if _is_logging: print("    overhead_usec: %s" % [overhead_usec])

	# Run callables
	if _is_setup:
		self._run_callables(overhead_usec)

func _run_callables(overhead_usec : int) -> void:
	var frame_budget_surplus_usec := clampi(_frame_budget_usec - overhead_usec, 0, INT64_MAX)
	var frame_budget_expenditure_usec := 0
	var is_working := true
	var call_count := 0
	var has_reasonable_starting_budget := frame_budget_surplus_usec - _frame_budget_threshold_usec > 0

	var did_work := false
	while has_reasonable_starting_budget and is_working:
		var before := Time.get_ticks_usec()

		# Get the next callable
		_mutex.lock()
		var entry := _to_call.pop_front()
		_mutex.unlock()

		var did_call := false
		if entry:
			var callable = entry["callable"]
			var args = entry["args"]
			if callable != null and callable.is_valid() and not callable.is_null():
				if args != null and typeof(args) == TYPE_ARRAY and not args.is_empty():
					callable.callv(args)
				else:
					callable.call()
				did_work = true
				did_call = true
				call_count += 1
			else:
				push_error("Callable not valid or missing target to call")

		var after := Time.get_ticks_usec()
		var used := clampi(after - before, 0, INT64_MAX)
		frame_budget_surplus_usec = clampi(frame_budget_surplus_usec - used, 0, INT64_MAX)
		frame_budget_expenditure_usec = clampi(frame_budget_expenditure_usec + used, 0, INT64_MAX)

		# Stop running callables if there are none left, or we are over budget
		if not did_call or frame_budget_surplus_usec < _frame_budget_threshold_usec:
			is_working = false

	_mutex.lock()
	var waiting_count := _to_call.size()
	_mutex.unlock()

	#if _is_logging and call_count > 0:
	if call_count > 0:
		self.emit_signal("log", _frame_budget_usec, overhead_usec, frame_budget_expenditure_usec, frame_budget_surplus_usec, call_count, waiting_count)

	if waiting_count != _prev_waiting_count:
		self.emit_signal("waiting_count_change", waiting_count)

	if _is_too_busy_to_work and not _was_working and did_work:
		_is_too_busy_to_work = false
		self.emit_signal("engine_not_busy", waiting_count)

	if not _is_too_busy_to_work and _was_working and not did_work and waiting_count > 0:
		_is_too_busy_to_work = true
		self.emit_signal("engine_too_busy", waiting_count)

	var used_usec := clampi(Time.get_ticks_usec() - _main_iteration_start_ticks, 0, INT64_MAX)
	if used_usec > _frame_budget_usec:
		self.emit_signal("over_frame_budget", used_usec, _frame_budget_usec)

	_prev_waiting_count = waiting_count
	_was_working = did_work

func start(frame_budget_usec : int, frame_budget_threshold_usec : int) -> void:
	# Get the best method of getting frame start time
	if Engine.has_method("get_frame_ticks"):
		_fn_get_frame_start_ticks_usec = Callable(Engine, "get_frame_ticks")
	else:
		_fn_get_frame_start_ticks_usec = Callable(Time, "get_ticks_usec")
	print("GodotCallThrottled using '%s' to get frame start time" % _fn_get_frame_start_ticks_usec)

	_frame_budget_usec = frame_budget_usec
	_frame_budget_threshold_usec = frame_budget_threshold_usec
	self.get_tree().connect("physics_frame", Callable(self, "_on_start_physics_frame"))
	_is_setup = true

func call_throttled(cb : Callable, args := []) -> void:
	if not _is_setup:
		push_error("Please run CallThrottled.start before calling")
		return

	var entry := {
		"callable" : cb,
		"args" : args,
	}

	_mutex.lock()
	_to_call.push_back(entry)
	_mutex.unlock()
