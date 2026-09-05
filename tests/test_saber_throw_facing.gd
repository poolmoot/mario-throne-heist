extends SceneTree


func _face_xz(skeleton: Skeleton3D) -> Vector3:
	var hips := skeleton.global_transform * skeleton.get_bone_global_pose(skeleton.find_bone("Hips")).origin
	var front := skeleton.global_transform * skeleton.get_bone_global_pose(skeleton.find_bone("headfront")).origin
	var face := Vector3(front.x - hips.x, 0.0, front.z - hips.z)
	return face.normalized() if face.length() > 0.001 else Vector3.ZERO


func _throw_after_run(player_yaw: float) -> Dictionary:
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
	var face := _face_xz(skeleton)
	player.attack()

	var saber: Node3D = null
	for child in player.get_parent().get_children():
		if child != player and child is Area3D and String(child.name).begins_with("Lightsaber"):
			saber = child
			break
	if saber == null:
		player.queue_free()
		await process_frame
		return {"error": "no saber spawned"}

	var start := saber.global_position
	for _i in 8:
		await physics_frame
	var travel := saber.global_position - start
	travel.y = 0.0
	var result := {
		"face": face,
		"travel": travel,
		"dot": travel.normalized().dot(face) if travel.length() > 0.05 and face.length() > 0.05 else -2.0,
	}
	player.queue_free()
	if is_instance_valid(saber):
		saber.queue_free()
	await process_frame
	return result


func _initialize() -> void:
	var identity := await _throw_after_run(0.0)
	print("yaw0 face=%s travel=%s dot=%s" % [identity.get("face"), identity.get("travel"), identity.get("dot")])
	if identity.get("error"):
		push_error(identity["error"])
		quit(1)
		return
	if identity["dot"] < 0.9:
		push_error("At yaw 0 saber should fly the way Mario faces, dot=%s" % identity["dot"])
		quit(1)
		return

	var flipped := await _throw_after_run(PI)
	print("yaw180 face=%s travel=%s dot=%s" % [flipped.get("face"), flipped.get("travel"), flipped.get("dot")])
	if flipped.get("error"):
		push_error(flipped["error"])
		quit(1)
		return
	if flipped["dot"] < 0.9:
		push_error("At yaw 180 saber should fly the way Mario faces, dot=%s" % flipped["dot"])
		quit(1)
		return

	print("PASS: thrown saber follows Mario facing at yaw 0 and 180")
	quit()
