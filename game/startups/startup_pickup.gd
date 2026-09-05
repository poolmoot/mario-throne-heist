extends Area3D

const HOVER_HEIGHT := 0.7
const HOVER_AMP := 0.14
const HOVER_SPEED := 2.4
const LOGO_EXTS := ["png", "svg", "jpg", "jpeg", "webp"]

var company_id := ""
var company_name := ""
var valuation := 0
var _taken := false
var _t := 0.0

@onready var _board: MeshInstance3D = $Board
@onready var _label: Label3D = $Label
@onready var _collect_audio: AudioStreamPlayer3D = $CollectAudio


func _ready() -> void:
	monitoring = true
	collision_layer = 0
	collision_mask = 1
	body_entered.connect(_on_body_entered)
	position.y = HOVER_HEIGHT


func setup(entry: Dictionary) -> void:
	company_id = str(entry.get("id", "startup"))
	company_name = str(entry.get("name", company_id))
	valuation = int(entry.get("valuation", 0))
	name = "Startup_%s" % company_id
	if is_inside_tree():
		_apply_look(entry)
	else:
		call_deferred("_apply_look", entry)


func _apply_look(entry: Dictionary) -> void:
	if _board == null:
		_board = get_node_or_null("Board") as MeshInstance3D
	if _label == null:
		_label = get_node_or_null("Label") as Label3D
	var color := Color(entry.get("color", "#888888"))
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	mat.albedo_color = Color.WHITE
	var texture := _logo_texture(company_id)
	if texture:
		mat.albedo_texture = texture
	else:
		mat.albedo_color = color
	if _board:
		_board.material_override = mat
	if _label:
		_label.text = company_name


func _logo_texture(id: String) -> Texture2D:
	for ext in LOGO_EXTS:
		var path := "res://game/startups/logos/%s.%s" % [id, ext]
		if ResourceLoader.exists(path):
			var texture := load(path) as Texture2D
			if texture:
				return texture
	return null


func _process(delta: float) -> void:
	_t += delta
	position.y = HOVER_HEIGHT + sin(_t * HOVER_SPEED) * HOVER_AMP
	var cam := get_viewport().get_camera_3d()
	if cam:
		var to_cam := cam.global_position - global_position
		to_cam.y = 0.0
		if to_cam.length_squared() > 0.01:
			look_at(global_position + to_cam, Vector3.UP)


func _on_body_entered(body: Node3D) -> void:
	if _taken:
		return
	if not (body is Player or body.name == "Player"):
		return
	_taken = true
	var flow := get_tree().get_first_node_in_group("game_flow")
	if flow and flow.has_method("collect_startup"):
		flow.collect_startup(valuation)
	_collect()


func _collect() -> void:
	if _collect_audio:
		_collect_audio.play()
	hide()
	monitoring = false
	if _collect_audio:
		await _collect_audio.finished
	queue_free()
