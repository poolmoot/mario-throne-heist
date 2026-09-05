extends SceneTree


func _initialize() -> void:
	var packed := load("res://game/enemies/stormtrooper.tscn") as PackedScene
	var trooper := packed.instantiate() as Node3D
	root.add_child(trooper)
	await process_frame
	for i in 8:
		await physics_frame

	var skeleton := trooper.find_child("Skeleton3D", true, false) as Skeleton3D
	if skeleton == null:
		push_error("stormtrooper skeleton missing")
		quit(1)
		return
	var min_y := INF
	var max_y := -INF
	for bone_i in skeleton.get_bone_count():
		var world := skeleton.global_transform * skeleton.get_bone_global_pose(bone_i).origin
		min_y = min(min_y, world.y)
		max_y = max(max_y, world.y)
	var height := max_y - min_y
	print("stormtrooper skeleton height=%s m (y %s .. %s)" % [height, min_y, max_y])

	# 1.5× the imported 1.8 m City Guard pack.
	if height < 2.4 or height > 3.5:
		push_error("stormtrooper skeleton height is %s m; expected ~2.9 m (1.5× pack)" % height)
		quit(1)
		return

	print("PASS: stormtrooper is human-sized")
	quit()
