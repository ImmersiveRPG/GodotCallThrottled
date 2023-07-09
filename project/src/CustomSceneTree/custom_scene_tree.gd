# Copyright (c) 2023 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
# This file is licensed under the MIT License
# https://github.com/ImmersiveRPG/ExampleGodotThrottle

extends SceneTree

class_name CustomSceneTree

var _gct = null

func _initialize() -> void:
	print("Main Loop Initialized")

func _finalize() -> void:
	print("Main Loop Finalized")


func _physics_process(_delta : float) -> bool:
	if Global._is_logging: print("Frame: %s" % [self.get_frame()])

	# The GodotCallThrottled singleton may not be loaded yet, so we manually check for it here
	if _gct == null:
		_gct = self.root.get_node_or_null("GodotCallThrottled")

	if _gct:
		_gct.loop()

	return false




