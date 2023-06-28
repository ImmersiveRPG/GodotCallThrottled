# Copyright (c) 2023 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
# This file is licensed under the MIT License
# https://github.com/ImmersiveRPG/ExampleGodotThrottle

extends SceneTree

class_name CustomSceneTree


var _throttler = null
var _physics_process_start_ticks := 0
var _physics_process_end_ticks := 0
var _last_node_scene := preload("res://src/LastNode/LastNode.tscn")
var _last_node = null

func _initialize() -> void:
	print("Main Loop Initialized")

func _finalize() -> void:
	print("Main Loop Finalized")
	pass

func _physics_process(_delta : float) -> bool:
	#OS.delay_msec(1000)
	_physics_process_start_ticks = Time.get_ticks_msec()
	#print("_physics_process_start_ticks: %s" % [_physics_process_start_ticks])

	# The Throttler singleton may not be loaded yet, so we manually check for it here
	if _throttler == null:
		_throttler = self.root.get_node_or_null("Throttler")

	# Run callables
	if _throttler and _throttler._is_setup:
		_throttler._run_callables()

	# Just return if there isn't a scene yet
	var target = self.current_scene
	if not target: return false

	# Forget last node if it has been freed
	if not is_instance_valid(_last_node):
		_last_node = null

	# Create the last node in tree
	if not _last_node:
		_last_node = _last_node_scene.instantiate()
		target.add_child(_last_node)

	# Move last node to be last in tree
	if _last_node.get_index() != target.get_child_count()-1:
		target.move_child(_last_node, target.get_child_count()-1)

	#print("---- end _physics_process: %s" % [Time.get_ticks_msec()])
	#OS.delay_msec(1000)
	return false

func _physics_process_done() -> void:
	_physics_process_end_ticks = Time.get_ticks_msec()
	#print("_physics_process_end_ticks: %s" % [_physics_process_end_ticks])
	print("physics frame time: %s" % [_physics_process_end_ticks - _physics_process_start_ticks])

func _process(_delta : float) -> bool:
	#print("++++ _process: %s" % [Time.get_ticks_msec()])

	return false


