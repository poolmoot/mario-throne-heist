extends SceneTree


func _look_xz(node: Node3D) -> Vector3:
	var look := -node.global_transform.basis.z
	look.y = 0.0
	return look.normalized() if look.length() > 0.001 else Vector3.ZERO


func _face_xz(player: Node3D) -> Vector3:
	var rotation_root := player.get_node("CharacterRotationRoot") as Node3D
	var face := rotation_root.global_transform.basis.z
	face.y = 0.0
	return face.normalized() if face.length() > 0.001 else Vector3.ZERO


func _initialize() -> void:
	var packed := load("res://player/player.tscn") as PackedScene
	var player := packed.instantiate() as CharacterBody3D
	root.add_child(player)
	await process_frame
	await process_frame

	var camera := player.get_node("CameraController/PlayerCamera") as Camera3D
	var look_before := _look_xz(camera)

	Input.action_press("move_right")
	for _i in 45:
		await physics_frame
	Input.action_release("move_right")
	for _i in 90:
		await physics_frame

	var look_after := _look_xz(camera)
	var face := _face_xz(player)
	var camera_held := look_before.dot(look_after)
	var face_turned := look_after.dot(face)
	print("look_before=%s look_after=%s face=%s camera_held=%s face_turned=%s" % [look_before, look_after, face, camera_held, face_turned])

	if camera_held < 0.95:
		push_error("Orbit camera should keep its yaw when Mario strafes. before=%s after=%s" % [look_before, look_after])
		quit(1)
		return

	if face_turned > 0.85:
		push_error("Mario should turn independently of the camera. face=%s look=%s" % [face, look_after])
		quit(1)
		return

	print("PASS: orbit camera keeps yaw while Mario turns")
	quit()
