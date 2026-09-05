class_name StartupCatalog
extends RefCounted

const PATH := "res://game/startups/startups.json"


static func load_entries() -> Array:
	var file := FileAccess.open(PATH, FileAccess.READ)
	if file == null:
		return []
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_ARRAY:
		return []
	return parsed


static func format_valuation(amount: int) -> String:
	if amount >= 1_000_000_000:
		return _trim(float(amount) / 1_000_000_000.0) + "B"
	if amount >= 1_000_000:
		return _trim(float(amount) / 1_000_000.0) + "M"
	return _trim(float(amount) / 1000.0) + "k"


static func _trim(value: float) -> String:
	var rounded: float = snapped(value, 0.1)
	if is_equal_approx(rounded, round(rounded)):
		return str(int(round(rounded)))
	return "%.1f" % rounded
