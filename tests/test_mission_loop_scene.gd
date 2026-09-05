extends SceneTree


func _initialize() -> void:
	var packed := load("res://game/first_build.tscn") as PackedScene
	var scene := packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	for path in ["Mission", "Mission/StartGate", "Mission/Throne", "Mission/ExitZone", "Mission/HUD", "Troopers/GuardA", "Troopers/GuardB", "Troopers/GuardC", "Troopers/GuardD"]:
		if scene.get_node_or_null(path) == null:
			push_error("missing mission node %s" % path)
			quit(1)
			return

	var spawn := Vector3(-72, 0, -64)
	var gate := scene.get_node("Mission/StartGate") as Node3D
	var guard_a := scene.get_node("Troopers/GuardA") as Node3D
	var guard_xz := Vector3(guard_a.global_position.x, 0, guard_a.global_position.z)
	var spawn_xz := Vector3(spawn.x, 0, spawn.z)
	if guard_xz.distance_to(spawn_xz) < 28.0:
		push_error("GuardA is blocking the start, distance=%s" % spawn_xz.distance_to(guard_xz))
		quit(1)
		return
	if guard_xz.distance_to(Vector3(gate.global_position.x, 0, gate.global_position.z)) < 20.0:
		push_error("GuardA should not stand on the start gate")
		quit(1)
		return

	print("PASS: mission loop nodes exist")
	quit()
