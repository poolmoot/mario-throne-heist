extends SceneTree


func _initialize() -> void:
	var packed := load("res://game/enemies/stormtrooper.tscn") as PackedScene
	if packed == null:
		push_error("stormtrooper scene missing")
		quit(1)
		return
	var trooper := packed.instantiate() as CharacterBody3D
	if trooper == null:
		push_error("each stormtrooper must be its own CharacterBody3D")
		quit(1)
		return
	root.add_child(trooper)
	await process_frame
	if not trooper.is_in_group("troopers"):
		push_error("stormtrooper must be in troopers group")
		quit(1)
		return
	if not ("patrol_to" in trooper):
		push_error("stormtrooper must expose patrol_to")
		quit(1)
		return
	if trooper.get_node_or_null("Visual/Model") == null:
		push_error("stormtrooper must instance the animated guard model")
		quit(1)
		return
	print("PASS: individual stormtrooper")
	quit()
