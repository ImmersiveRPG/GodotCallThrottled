# Copyright (c) 2023 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
# This file is licensed under the MIT License
# https://github.com/ImmersiveRPG/ExampleGodotThrottle

extends Node
#class_name GodotCallThrottled

var _main_iteration_start_ticks := 0
var _main_iteration_end_ticks := 0
var _last_node_scene := preload("res://addons/godot_call_throttled/LastNode/last_node.tscn")
var _last_node = null
var _throttler = null

func _ready() -> void:
	var cb := Callable(self, "_tree_changed")
	self.get_tree().connect("tree_changed", cb) 

func loop() -> void:
	self._main_iteration_start()

	# The Throttler singleton may not be loaded yet, so we manually check for it here
	if _throttler == null:
		_throttler = self.get_tree().root.get_node_or_null("Throttler")

	# Just return if there isn't a scene yet
	var target = self.get_tree().root
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
		print("Moved last node to end")
		target.move_child(_last_node, target.get_child_count()-1)

func _tree_changed() -> void:
	#print("Called tree_changed ...")
	pass

func _main_iteration_start() -> void:
	_main_iteration_start_ticks = Time.get_ticks_msec()
	_main_iteration_end_ticks = _main_iteration_start_ticks
	if Global._is_logging: print("    _main_iteration_start: %s" % [_main_iteration_start_ticks])

func _main_iteration_done() -> void:
	_main_iteration_end_ticks = Time.get_ticks_msec()
	if Global._is_logging: print("    _main_iteration_done: %s" % [_main_iteration_end_ticks])
	var used_physics_ticks := clampi(_main_iteration_end_ticks - _main_iteration_start_ticks, 0, Global.INT32_MAX)
	if Global._is_logging: print("    used_physics_ticks: %s" % [used_physics_ticks])

	# Run callables
	if _throttler and _throttler._is_setup:
		_throttler._run_callables(used_physics_ticks)
