# Copyright (c) 2023 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
# This file is licensed under the MIT License
# https://github.com/ImmersiveRPG/ExampleGodotThrottle

extends Node



func _process(_delta : float) -> void:
	var tree = self.get_tree() as CustomSceneTree
	if tree:
		tree._main_iteration_done()


