extends SceneTree


func _face_xz(skeleton: Skeleton3D) -> Vector3:
	var hips := skeleton.global_transform * skeleton.get_bone_global_pose(skeleton.find_bone("Hips")).origin
	var front := skeleton.global_transform * skeleton.get_bone_global_pose(skeleton.find_bone("headfront")).origin
	var face := Vector3(front.x - hips.x, 0.0, front.z - hips.z)
	return face.normalized() if face.length() > 0.001 else Vector3.ZERO


func _run_forward(player_yaw: float) -> Dictionary:
	var packed := load("res://player/player.tscn") as PackedScene
	var player := packed.instantiate() as CharacterBody3D
	player.rotation.y = player_yaw
	root.add_child(player)
	await process_frame
	await process_frame

	Input.action_press("move_up")
	for i in 45:
		await physics_frame
	Input.action_release("move_up")

	var mario := player.get_node("CharacterRotationRoot/MarioVisual") as Node3D
	var skeleton := mario.find_child("Skeleton3D", true, false) as Skeleton3D
	var vel := Vector3(player.velocity.x, 0.0, player.velocity.z)
	var face := _face_xz(skeleton)
	var result := {
		"vel": vel,
		"face": face,
		"dot": face.dot(vel.normalized()) if vel.length() > 0.05 else -2.0,
	}
	player.queue_free()
	await process_frame
	return result


func _initialize() -> void:
	var identity := await _run_forward(0.0)
	print("yaw0 vel=%s face=%s dot=%s" % [identity["vel"], identity["face"], identity["dot"]])
	if identity["dot"] < 0.9:
		push_error("At yaw 0 Mario should face the run direction, dot=%s" % identity["dot"])
		quit(1)
		return

	# first_build spawns the player at 180° so the corner faces into the city.
	var flipped := await _run_forward(PI)
	print("yaw180 vel=%s face=%s dot=%s" % [flipped["vel"], flipped["face"], flipped["dot"]])
	if flipped["dot"] < 0.9:
		push_error("At yaw 180 Mario should still face the run direction, not the camera. dot=%s" % flipped["dot"])
		quit(1)
		return

	print("PASS: Mario faces the run direction at yaw 0 and 180")
	quit()
