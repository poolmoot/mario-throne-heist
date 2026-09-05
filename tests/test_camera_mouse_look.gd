extends SceneTree


func _look_xz(node: Node3D) -> Vector3:
	var look := -node.global_transform.basis.z
	look.y = 0.0
	return look.normalized() if look.length() > 0.001 else Vector3.ZERO


func _initialize() -> void:
	var packed := load("res://player/player.tscn") as PackedScene
	var player := packed.instantiate() as CharacterBody3D
	root.add_child(player)
	await process_frame
	await process_frame

	var camera := player.get_node("CameraController/PlayerCamera") as Camera3D
	var controller := player.get_node("CameraController")
	var look_before := _look_xz(camera)

	controller.add_look_input(Vector2(400.0, 0.0))
	await process_frame
	await process_frame

	var look_after := _look_xz(camera)
	print("look_before=%s look_after=%s mouse_mode=%s" % [look_before, look_after, Input.mouse_mode])
	if look_before.dot(look_after) > 0.95:
		push_error("Mouse motion should orbit the camera. before=%s after=%s" % [look_before, look_after])
		quit(1)
		return

	print("PASS: mouse look orbits the camera")
	quit()
