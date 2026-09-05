class_name Minimap
extends Control

const VIEW_RADIUS := 36.0
const RIM := 8.0
const CITY_GRID := 19
const CITY_BLOCK := 3
const CITY_CELL_M := 8.0
const KIND_OUTSIDE := 0
const KIND_ROAD := 1
const KIND_PLAZA := 2
const KIND_BUILDING := 3
const ROAD_COLOR := Color(0.78, 0.80, 0.84, 1.0)
const PLAZA_COLOR := Color(0.32, 0.34, 0.36, 1.0)
const BUILDING_COLOR := Color(0.18, 0.20, 0.22, 1.0)
const BUILDING_ALT := Color(0.14, 0.15, 0.17, 1.0)
const GROUND_COLOR := Color(0.08, 0.09, 0.10, 1.0)
const PLAYER_COLOR := Color(1.0, 1.0, 1.0, 1.0)
const THRONE_COLOR := Color(0.95, 0.78, 0.18, 1.0)
const EXIT_COLOR := Color(0.35, 0.92, 0.48, 1.0)
const GATE_COLOR := Color(0.35, 0.7, 1.0, 1.0)
const TROOPER_COLOR := Color(0.95, 0.22, 0.22, 1.0)

const GameFlowScript := preload("res://game/mission/game_flow.gd")

var _flow: Node
var _city_tex: ImageTexture
var _fill: Control


func bind(flow: Node) -> void:
	_flow = flow


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_children = Control.CLIP_CHILDREN_ONLY
	texture_filter = TEXTURE_FILTER_NEAREST
	_city_tex = ImageTexture.create_from_image(bake_city_map(256))
	_fill = Control.new()
	_fill.name = "Fill"
	_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fill.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fill.draw.connect(_on_fill_draw)
	add_child(_fill)
	set_process(true)


func _process(_delta: float) -> void:
	if _fill:
		_fill.queue_redraw()


func _draw() -> void:
	draw_circle(size * 0.5, minf(size.x, size.y) * 0.5 - 0.5, Color.WHITE, true, -1.0, true)


func _on_fill_draw() -> void:
	if _fill:
		_paint(_fill)


static func world_to_map(
	world: Vector3,
	map_size: Vector2,
	origin: Vector3 = Vector3.ZERO,
	forward: Vector3 = Vector3(0, 0, -1),
	view_radius: float = VIEW_RADIUS
) -> Vector2:
	var center := map_size * 0.5
	var radius := minf(map_size.x, map_size.y) * 0.5 - RIM
	var rel := Vector2(world.x - origin.x, world.z - origin.z)
	var f := Vector2(forward.x, forward.z)
	if f.length_squared() < 0.0001:
		f = Vector2(0, -1)
	else:
		f = f.normalized()
	var right := Vector2(-f.y, f.x)
	var offset := Vector2(rel.dot(right), -rel.dot(f)) / view_radius * radius
	if offset.length() > radius:
		offset = offset.normalized() * radius
	return center + offset


static func cell_kind(cell: Vector2i) -> int:
	if cell.x < -1 or cell.y < -1 or cell.x > CITY_GRID or cell.y > CITY_GRID:
		return KIND_OUTSIDE
	if cell.x < 0 or cell.y < 0 or cell.x >= CITY_GRID or cell.y >= CITY_GRID:
		return KIND_BUILDING
	var plaza := _plaza_origin()
	if cell.x >= plaza.x and cell.x <= plaza.x + 1 and cell.y >= plaza.y and cell.y <= plaza.y + 1:
		return KIND_PLAZA
	if cell.x % CITY_BLOCK == 0 or cell.y % CITY_BLOCK == 0:
		return KIND_ROAD
	return KIND_BUILDING


static func bake_city_map(pixels: int) -> Image:
	var img := Image.create(pixels, pixels, false, Image.FORMAT_RGBA8)
	img.fill(GROUND_COLOR)
	for y in pixels:
		for x in pixels:
			var world := _texel_to_world(Vector2i(x, y), pixels)
			var cell := world_to_cell(world)
			img.set_pixel(x, y, _kind_color(cell_kind(cell), cell))
	return img


static func city_texel(world: Vector3, pixels: int) -> Vector2i:
	var origin := _tex_world_origin()
	var span := _tex_world_span()
	var u := (world.x - origin) / span
	var v := (world.z - origin) / span
	return Vector2i(
		clampi(int(floor(u * float(pixels))), 0, pixels - 1),
		clampi(int(floor(v * float(pixels))), 0, pixels - 1),
	)


static func world_to_cell(world: Vector3) -> Vector2i:
	var origin := -float(CITY_GRID) * CITY_CELL_M * 0.5
	return Vector2i(
		int(floor((world.x - origin) / CITY_CELL_M)),
		int(floor((world.z - origin) / CITY_CELL_M)),
	)


static func _tex_world_origin() -> float:
	return -float(CITY_GRID + 2) * CITY_CELL_M * 0.5


static func _tex_world_span() -> float:
	return float(CITY_GRID + 2) * CITY_CELL_M


static func _texel_to_world(px: Vector2i, pixels: int) -> Vector3:
	var origin := _tex_world_origin()
	var span := _tex_world_span()
	var x := origin + (float(px.x) + 0.5) / float(pixels) * span
	var z := origin + (float(px.y) + 0.5) / float(pixels) * span
	return Vector3(x, 0.0, z)


static func _plaza_origin() -> Vector2i:
	var junction := int(float(CITY_GRID) / float(CITY_BLOCK * 2)) * CITY_BLOCK
	return Vector2i(junction + 1, junction + 1)


static func _kind_color(kind: int, cell: Vector2i) -> Color:
	match kind:
		KIND_ROAD:
			return ROAD_COLOR
		KIND_PLAZA:
			return PLAZA_COLOR
		KIND_BUILDING:
			if absi(cell.x * 3 + cell.y * 7) % 2 == 0:
				return BUILDING_COLOR
			return BUILDING_ALT
		_:
			return GROUND_COLOR


func _paint(ci: CanvasItem) -> void:
	var center := size * 0.5
	var radius := _radius()
	ci.draw_circle(center, radius, GROUND_COLOR, true, -1.0, true)

	var origin := Vector3.ZERO
	var forward := Vector3(0, 0, -1)
	var player: Node3D = null
	if _flow == null:
		_flow = get_tree().get_first_node_in_group("game_flow")
	if _flow:
		player = _flow.player
	if player:
		origin = player.global_position
		var spin := player.get_node_or_null("CharacterRotationRoot") as Node3D
		var facing := spin if spin else player
		forward = -facing.global_transform.basis.z

	if _city_tex:
		var heading := atan2(-forward.x, -forward.z)
		var meters_to_px := radius / VIEW_RADIUS
		var tex_origin := _tex_world_origin()
		var tex_span := _tex_world_span()
		ci.draw_set_transform(center, heading, Vector2(meters_to_px, meters_to_px))
		ci.draw_texture_rect(
			_city_tex,
			Rect2(Vector2(tex_origin - origin.x, tex_origin - origin.z), Vector2(tex_span, tex_span)),
			false
		)
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	if _flow:
		_draw_marker(ci, _flow.get_node_or_null("StartGate") as Node3D, origin, forward, GATE_COLOR, 3.5)
		if _flow.state != GameFlowScript.State.ESCAPE and _flow.state != GameFlowScript.State.SUCCESS:
			_draw_marker(ci, _flow.get_node_or_null("Throne") as Node3D, origin, forward, THRONE_COLOR, 4.5)
		_draw_marker(ci, _flow.get_node_or_null("ExitZone") as Node3D, origin, forward, EXIT_COLOR, 4.0)
		for trooper in get_tree().get_nodes_in_group("troopers"):
			if trooper is Node3D:
				_draw_marker(ci, trooper, origin, forward, TROOPER_COLOR, 3.0)

	_draw_player_chevron(ci, center)
	var north := world_to_map(origin + Vector3(0, 0, -200), size, origin, forward)
	ci.draw_circle(north, 6.5, Color(0.05, 0.05, 0.05, 1.0), true, -1.0, true)
	ci.draw_string(ThemeDB.fallback_font, north + Vector2(-4, 4), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1, 1, 1, 1))
	ci.draw_arc(center, radius - 2.0, 0.0, TAU, 72, Color(0.02, 0.02, 0.03, 1.0), 6.0, true)
	ci.draw_arc(center, radius - 5.5, 0.0, TAU, 72, Color(0.62, 0.64, 0.68, 0.45), 1.4, true)


func _draw_marker(ci: CanvasItem, node: Node3D, origin: Vector3, forward: Vector3, color: Color, marker_radius: float) -> void:
	if node == null or not is_instance_valid(node):
		return
	var pos := world_to_map(node.global_position, size, origin, forward)
	ci.draw_circle(pos, marker_radius + 1.4, Color(0, 0, 0, 0.85), true, -1.0, true)
	ci.draw_circle(pos, marker_radius, color, true, -1.0, true)


func _draw_player_chevron(ci: CanvasItem, center: Vector2) -> void:
	var tip := center + Vector2(0, -8)
	var left := center + Vector2(-5.5, 6)
	var right := center + Vector2(5.5, 6)
	ci.draw_colored_polygon(PackedVector2Array([tip + Vector2(0, -1.5), left + Vector2(-1.4, 1.2), right + Vector2(1.4, 1.2)]), Color(0, 0, 0, 0.9))
	ci.draw_colored_polygon(PackedVector2Array([tip, left, right]), PLAYER_COLOR)


func _radius() -> float:
	return minf(size.x, size.y) * 0.5 - 1.0
