extends SceneTree

const PARK_CENTER := Vector3(12, 0, 12)


func _initialize() -> void:
	var packed := load("res://game/mission/throne.tscn") as PackedScene
	var throne := packed.instantiate() as Node3D
	root.add_child(throne)
	await process_frame

	var crown := throne.get_node_or_null("Crown") as Node3D
	if crown == null:
		push_error("throne must instance the crown model")
		quit(1)
		return

	var start_y := crown.position.y
	if start_y < 0.2 or start_y > 1.2:
		push_error("crown should hover near the ground, y=%s" % start_y)
		quit(1)
		return

	for _i in 20:
		await process_frame
	if is_equal_approx(crown.position.y, start_y) and is_equal_approx(crown.rotation.y, 0.0):
		push_error("crown should bob or spin while floating")
		quit(1)
		return

	var scene_packed := load("res://game/first_build.tscn") as PackedScene
	var scene := scene_packed.instantiate() as Node3D
	root.add_child(scene)
	await process_frame

	var placed := scene.get_node("Mission/Throne") as Node3D
	var park_xz := Vector3(PARK_CENTER.x, placed.global_position.y, PARK_CENTER.z)
	if placed.global_position.distance_to(park_xz) > 4.0:
		push_error("crown should sit in the park, got %s" % placed.global_position)
		quit(1)
		return

	print("PASS: crown floats near the ground in the park")
	quit()
