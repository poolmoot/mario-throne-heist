extends SceneTree


func _initialize() -> void:
	var packed := load("res://assets/characters/mario/mario_visual.tscn") as PackedScene
	var mario := packed.instantiate() as Node
	root.add_child(mario)
	await process_frame
	await process_frame

	var anim := mario.get_node("Model/AnimationPlayer") as AnimationPlayer
	if not anim.has_animation("Idle") or not anim.has_animation("Walk") or not anim.has_animation("Run") or not anim.has_animation("Jump"):
		push_error("Missing Studio clips on Mario AnimationPlayer")
		quit(1)
		return

	print("after_ready clip=%s playing=%s" % [anim.current_animation, anim.is_playing()])
	if anim.current_animation != "Idle" or not anim.is_playing():
		push_error("Mario should start on Idle")
		quit(1)
		return

	mario.set_moving(true)
	mario.set_moving_speed(0.3)
	await process_frame
	print("after_walk clip=%s playing=%s" % [anim.current_animation, anim.is_playing()])
	if anim.current_animation != "Walk":
		push_error("Mario should play Walk when moving slowly")
		quit(1)
		return

	mario.set_moving_speed(1.0)
	await process_frame
	print("after_run clip=%s" % anim.current_animation)
	if anim.current_animation != "Run":
		push_error("Mario should play Run at full speed")
		quit(1)
		return

	mario.jump()
	await process_frame
	print("after_jump clip=%s" % anim.current_animation)
	if anim.current_animation != "Jump":
		push_error("Mario should play Jump")
		quit(1)
		return

	print("PASS: Mario Studio clips idle/walk/run/jump")
	quit()
