extends SceneTree


func _initialize() -> void:
	var packed := load("res://assets/environment/kaykit/kaykit_city.tscn") as PackedScene
	var city := packed.instantiate() as Node3D
	root.add_child(city)
	await process_frame
	await process_frame

	var billboards: Array[MeshInstance3D] = []
	_collect_billboards(city, billboards)
	if billboards.size() < 6:
		push_error("expected several building billboards, got %s" % billboards.size())
		quit(1)
		return

	var buildings := _count_named(city.get_node("Visuals/Tiles"), "building_")
	if billboards.size() * 2 >= buildings:
		push_error("billboards should be on some buildings, not most (%s / %s)" % [billboards.size(), buildings])
		quit(1)
		return

	var logos := {}
	for board in billboards:
		var mesh := board.mesh as QuadMesh
		if mesh == null:
			push_error("%s should use a QuadMesh" % board.name)
			quit(1)
			return
		var world_width := mesh.size.x * board.global_transform.basis.x.length()
		if world_width < 3.0 or world_width > 4.0:
			push_error("%s world width is %s m; expected 3–4 m" % [board.name, world_width])
			quit(1)
			return
		var material := board.material_override as StandardMaterial3D
		if material == null or material.albedo_texture == null:
			push_error("%s is missing a logo texture" % board.name)
			quit(1)
			return
		logos[String(material.albedo_texture.resource_path).get_file().get_basename()] = true

	if not logos.has("summer_engine") or not logos.has("antler"):
		push_error("both logos should appear, got %s" % logos.keys())
		quit(1)
		return

	print("PASS: %s billboards at 3–4 m with both logos" % billboards.size())
	quit()


func _collect_billboards(node: Node, out: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D and str(node.name).begins_with("billboard_"):
		out.append(node)
	for child in node.get_children():
		_collect_billboards(child, out)


func _count_named(node: Node, prefix: String) -> int:
	var n := 0
	if str(node.name).begins_with(prefix):
		n += 1
	for child in node.get_children():
		n += _count_named(child, prefix)
	return n
