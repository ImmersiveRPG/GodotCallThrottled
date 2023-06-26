# Copyright (c) 2023 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
# This file is licensed under the MIT License
# https://github.com/ImmersiveRPG/ExampleGodotThrottle

extends Node3D

var _is_running := false
var _to_call := []
var _mutex := Mutex.new()

func _start_loop(frame_budget_msec : int, frame_budget_threshold_msec : int) -> void:
	while _is_running:
		# Wait here until the next process frame starts
		await self.get_tree().process_frame

		var frame_budget_remaining_msec := frame_budget_msec
		var frame_budget_used_msec := 0
		var is_working := true
		var call_count := 0
		while is_working:
			var before := Time.get_ticks_msec()

			# Get the next callable
			_mutex.lock()
			var entry = _to_call.pop_front()
			_mutex.unlock()

			var did_call := false
			if entry:
				var callable = entry["callable"]
				var args = entry["args"]
				if callable != null and callable.is_valid():
					if args != null and typeof(args) == TYPE_ARRAY and not args.is_empty():
						callable.callv(args)
					else:
						callable.call()
					did_call = true
					call_count += 1

			var after := Time.get_ticks_msec()
			var used := after - before
			frame_budget_remaining_msec -= used
			frame_budget_used_msec += used

			# Stop running callables if there are none left, or we are over budget
			if not did_call or frame_budget_remaining_msec < frame_budget_threshold_msec:
				is_working = false

		if call_count > 0:
			print("budget:%s, used:%s, remaining:%s, calls:%s" % [frame_budget_msec, frame_budget_used_msec, frame_budget_remaining_msec, call_count])

func start(frame_budget_msec : int, frame_budget_threshold_msec : int) -> void:
	_is_running = true

	self.call_deferred("_start_loop", frame_budget_msec, frame_budget_threshold_msec)

func stop() -> void:
	_is_running = false

func call_throttled(cb : Callable, args := []) -> void:
	var entry := {
		"callable" : cb,
		"args" : args,
	}

	_mutex.lock()
	_to_call.push_back(entry)
	_mutex.unlock()
