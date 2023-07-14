# Godot replace call_deferred with call_throttled

```GDScript
func _ready() -> void:
	# FIXME: Update this to have callbacks
	var frame_budget_msec := roundi(1000 / Engine.get_physics_ticks_per_second())
	var frame_budget_threshold_msec := 5
	GodotCallThrottled.start(frame_budget_msec, frame_budget_threshold_msec)

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
