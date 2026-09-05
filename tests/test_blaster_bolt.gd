extends SceneTree


func _initialize() -> void:
	var packed := load("res://game/weapons/blaster_bolt.tscn") as PackedScene
	if packed == null:
		push_error("blaster bolt scene missing")
		quit(1)
		return
	var bolt := packed.instantiate() as Area3D
	root.add_child(bolt)
	await process_frame
	bolt.global_position = Vector3(0, 1.2, 0)
	bolt.velocity = Vector3(0, 0, 12)
	for _i in 6:
		await process_frame
	if bolt.global_position.z < 0.2:
		push_error("blaster bolt should travel forward")
		quit(1)
		return
	if not bolt.find_children("*", "Sprite3D", true, false).is_empty():
		push_error("blaster bolt must be 3D geometry, not a sprite image")
		quit(1)
		return
	var meshes := bolt.find_children("*", "MeshInstance3D", true, false)
	if meshes.size() < 2:
		push_error("blaster bolt should be a 3D core plus glow shell, meshes=%s" % meshes.size())
		quit(1)
		return
	if bolt.find_children("*", "OmniLight3D", true, false).is_empty():
		push_error("blaster bolt should emit light")
		quit(1)
		return
	print("PASS: blaster bolt flies")
	quit()
