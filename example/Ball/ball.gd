# Copyright (c) 2022-2024 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
# This file is licensed under the MIT License
# https://github.com/ImmersiveRPG/GodotCallThrottled

extends RigidBody3D

func _ready() -> void:
	pass


func _process(_delta : float) -> void:
	pass

func _physics_process(_delta : float) -> void:
	#print("    ball _physics_process: %s" % [Time.get_ticks_usec()])
	#OS.delay_usec(5000)
	pass
