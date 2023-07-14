# Godot replace call_deferred with call_throttled

```GDScript
func _ready() -> void:
	# Wait 1 second for the game engine to settle down
	await self.get_tree().create_timer(1).timeout

	# Setup GodotCallThrottled and callbacks
	var frame_budget_usec := floori(1000000 / float(Engine.get_physics_ticks_per_second()))
	var frame_budget_threshold_usec := 5000

	# Setup GodotCallThrottled and callbacks
	GodotCallThrottled.start(frame_budget_usec, frame_budget_threshold_usec)
	GodotCallThrottled.connect("waiting_count_change", Callable(self, "_on_waiting_count_change"))
	GodotCallThrottled.connect("engine_not_busy", Callable(self, "_on_engine_not_busy"))
	GodotCallThrottled.connect("engine_too_busy", Callable(self, "_on_engine_too_busy"))
	GodotCallThrottled.connect("over_frame_budget", Callable(self, "_on_over_frame_budget"))

func _on_waiting_count_change(waiting_count : int) -> void:
	print("There are %s calls waiting" % [waiting_count])

func _on_engine_not_busy(waiting_count : int) -> void:
	print("Started running calls again")

func _on_engine_too_busy(waiting_count : int) -> void:
	print("Too busy to run any calls!")

func _on_over_frame_budget(used_usec : int, budget_usec : int) -> void:
	print("The current frame took %s, but the budget was %s" % [used_usec, budget_usec])

func _on_button_pressed() -> void:
	var cb := func():
		var ball := _ball_scene.instantiate()
		self.add_child(ball)

	# Replace this
	for n in 500:
		cb.call_deferred()

	# With this
	for n in 500:
		GodotCallThrottled.call_throttled(cb)
```

# Video

https://www.youtube.com/watch?v=WLDM0tQ-XqE
