extends SceneTree

const Catalog := preload("res://game/startups/startup_catalog.gd")
const LOGO_EXTS := ["png", "svg", "jpg", "jpeg", "webp"]


func _initialize() -> void:
	var packed := load("res://game/startups/startup_pickup.tscn") as PackedScene
	var pickup := packed.instantiate() as Area3D
	root.add_child(pickup)

	var lunar := {
		"id": "lunar",
		"name": "Lunar",
		"valuation": 2800000000,
		"color": "#1B4DFF",
	}
	pickup.setup(lunar)
	await process_frame
	await process_frame

	var board := pickup.get_node("Board") as MeshInstance3D
	var mat := board.material_override as StandardMaterial3D
	if mat == null or mat.albedo_texture == null:
		push_error("Lunar pickup must use the real Lunar logo texture")
		quit(1)
		return

	for entry in Catalog.load_entries():
		var id := str(entry.get("id", ""))
		if not _has_logo(id):
			push_error("missing real logo for %s" % id)
			quit(1)
			return

	print("PASS: every startup pickup has a real logo texture")
	quit()


func _has_logo(id: String) -> bool:
	for ext in LOGO_EXTS:
		if ResourceLoader.exists("res://game/startups/logos/%s.%s" % [id, ext]):
			return true
	return false
