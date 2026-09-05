extends SceneTree


func _initialize() -> void:
	var packed := load("res://game/first_build.tscn") as PackedScene
	var scene := packed.instantiate()
	root.add_child(scene)
	await process_frame

	var mario := scene.get_node("Player/CharacterRotationRoot/MarioVisual") as Node3D
	var skeleton := mario.find_child("Skeleton3D", true, false) as Skeleton3D
	var min_y := INF
	var max_y := -INF
	for i in skeleton.get_bone_count():
		var world := skeleton.global_transform * skeleton.get_bone_global_pose(i).origin
		min_y = min(min_y, world.y)
		max_y = max(max_y, world.y)
	var height := max_y - min_y
	print("Mario skeleton height=%s m (y %s .. %s)" % [height, min_y, max_y])

	# Skinned height, not the bind-pose mesh AABB. Extra instance scale
	# cancels the GLB's 0.01 armature scale and leaves bones in centimeters.
	if height < 1.2 or height > 2.2:
		push_error("Mario skeleton height is %s m; expected ~1.2–2.2 m" % height)
		quit(1)
		return

	print("PASS: Mario skeleton height is %s m" % height)
	quit()
