# Copyright (c) 2023 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
# This file is licensed under the MIT License
# https://github.com/ImmersiveRPG/ExampleGodotThrottle

extends SceneTree

class_name CustomSceneTree


var _throttler = null

func _initialize() -> void:
	print("Main Loop Initialized")

func _finalize() -> void:
	print("Main Loop Finalized")
	pass

func _physics_process(_delta : float) -> bool:
	#print("!!!!!! _physics_process")
	if _throttler == null:
		_throttler = self.root.get_node_or_null("Throttler")

	if _throttler and _throttler._is_setup:
		_throttler._run_callables()

	return false

func _process(_delta : float) -> bool:
	#print("!!!!!! _process")

	return false


