extends SceneTree


func _initialize() -> void:
	var packed := load("res://game/weapons/lightsaber.tscn") as PackedScene
	var saber := packed.instantiate() as Area3D
	root.add_child(saber)
	await process_frame
	saber.global_position = Vector3(0, 1.25, 0)
	saber.throw(Vector3(0, 0, 1))
	for _i in 8:
		await physics_frame
	if saber.global_position.z < 1.0:
		push_error("lightsaber should fly forward, z=%s" % saber.global_position.z)
		quit(1)
		return
	var visual := saber.get_node("Visual") as Node3D
	var visual_scale := visual.scale.x
	if visual_scale < 2.5:
		push_error("lightsaber visual should be larger, scale=%s" % visual_scale)
		quit(1)
		return
	var collision := saber.get_node("CollisionShape3D") as CollisionShape3D
	var box := collision.shape as BoxShape3D
	if box.size.z < 1.5:
		push_error("lightsaber hitbox should match the larger blade, z=%s" % box.size.z)
		quit(1)
		return
	var blade_mat: StandardMaterial3D = null
	for child in saber.find_children("*", "MeshInstance3D", true, false):
		var mi := child as MeshInstance3D
		if mi.mesh == null:
			continue
		for s in mi.mesh.get_surface_count():
			var mat := mi.get_active_material(s) as StandardMaterial3D
			if mat and mat.emission_enabled and mat.emission.b > 0.4 and mat.emission_energy_multiplier >= 8.0:
				blade_mat = mat
				break
	if blade_mat == null:
		push_error("lightsaber blue blade should emit bright light")
		quit(1)
		return
	if saber.find_children("*", "OmniLight3D", true, false).is_empty():
		push_error("lightsaber should cast a real light")
		quit(1)
		return
	print("PASS: lightsaber flies forward")
	quit()
