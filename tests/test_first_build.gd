extends SceneTree

const NW_CORNER := Vector3(-72, 0.55, -64)


func _initialize() -> void:
	var packed := load("res://game/first_build.tscn") as PackedScene
	var scene := packed.instantiate()
	root.add_child(scene)

	for frame in 60:
		await physics_frame

	var player := scene.get_node("Player") as Node3D
	var camera := scene.get_node("Player/CameraController/PlayerCamera") as Camera3D
	var camera_distance := camera.global_position.distance_to(player.global_position)
	var corner_xz := Vector3(NW_CORNER.x, player.global_position.y, NW_CORNER.z)

	if player.global_position.y < -0.05:
		push_error("Player fell below the city floor: y=%s" % player.global_position.y)
		quit(1)
		return
	if player.global_position.distance_to(corner_xz) > 8.0:
		push_error("Player should spawn in the NW street corner, got %s" % player.global_position)
		quit(1)
		return
	if camera_distance < 8.0 or camera_distance > 14.0:
		push_error("Camera framing distance is invalid: %s" % camera_distance)
		quit(1)
		return

	print("PASS: player remains on the NW corner and camera framing is valid")
	quit()
