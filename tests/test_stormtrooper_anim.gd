extends SceneTree


func _initialize() -> void:
	var packed := load("res://game/enemies/stormtrooper.tscn") as PackedScene
	var trooper := packed.instantiate() as Node3D
	root.add_child(trooper)
	await process_frame
	await process_frame

	var mesh := trooper.find_child("char1", true, false) as MeshInstance3D
	if mesh == null or mesh.skin == null:
		push_error("stormtrooper mesh must stay skinned so Studio clips deform it")
		quit(1)
		return
	var skeleton := trooper.find_child("Skeleton3D", true, false) as Skeleton3D
	if skeleton == null or mesh.get_parent() != skeleton:
		push_error("stormtrooper mesh must stay under Skeleton3D")
		quit(1)
		return

	var visual := trooper.get_node("Visual")
	var anim := visual.get_node_or_null("Model/AnimationPlayer") as AnimationPlayer
	if anim == null or not anim.has_animation("Idle") or not anim.has_animation("Walk") or not anim.has_animation("Run"):
		push_error("Missing Studio clips Idle/Walk/Run on the guard runtime pack")
		quit(1)
		return

	visual.play_clip("walk")
	await process_frame
	if anim.current_animation != "Walk" or not anim.is_playing():
		push_error("play_clip walk should play Walk, got %s" % anim.current_animation)
		quit(1)
		return

	for i in 24:
		await process_frame
	var moved := false
	for bone_i in skeleton.get_bone_count():
		var pose := skeleton.get_bone_pose(bone_i)
		var rest := skeleton.get_bone_rest(bone_i)
		if pose.origin.distance_to(rest.origin) > 0.001:
			moved = true
			break
		if pose.basis.get_rotation_quaternion().angle_to(rest.basis.get_rotation_quaternion()) > 0.02:
			moved = true
			break
	if not moved:
		push_error("Walk clip did not deform skeleton bones")
		quit(1)
		return

	print("PASS: stormtrooper Studio clips skin and play")
	quit()
