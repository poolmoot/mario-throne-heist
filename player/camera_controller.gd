class_name CameraController extends Node3D

enum CAMERA_PIVOT { OVER_SHOULDER, THIRD_PERSON }

@export var invert_mouse_y := false
## Radians of camera rotation per pixel of mouse travel. Applied directly —
## never scaled by frame delta — so the camera feels identical at any FPS.
@export_range(0.0, 0.01, 0.0001) var mouse_sensitivity := 0.002
## Radians per second of camera rotation at full stick deflection.
@export_range(0.0, 8.0) var joystick_sensitivity := 1.0
@export var tilt_upper_limit := deg_to_rad(-60.0)
@export var tilt_lower_limit := deg_to_rad(60.0)

@onready var camera: Camera3D = $PlayerCamera
@onready var _over_shoulder_pivot: Node3D = $CameraOverShoulderPivot
@onready var _camera_spring_arm: SpringArm3D = $CameraSpringArm
@onready var _third_person_pivot: Node3D = $CameraSpringArm/CameraThirdPersonPivot
@onready var _camera_raycast: RayCast3D = $PlayerCamera/CameraRayCast

var _aim_target: Vector3
var _aim_collider: Node
var _pivot: Node3D
var _current_pivot_type: CAMERA_PIVOT
var _rotation_input: float
var _tilt_input: float
var _offset: Vector3
var _anchor: CharacterBody3D
var _euler_rotation: Vector3


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		add_look_input(event.relative)


func add_look_input(relative: Vector2) -> void:
	# Mouse relative is already a displacement (pixels moved this event),
	# so it converts straight to radians. += so several motion events in
	# one frame accumulate instead of overwriting each other.
	_rotation_input += -relative.x * mouse_sensitivity
	_tilt_input += -relative.y * mouse_sensitivity


func _process(delta: float) -> void:
	if not _anchor:
		return

	# Stick deflection is a rate (radians per second), so unlike the mouse
	# path it does get scaled by delta — and by the joystick sensitivity,
	# which was previously exported but never applied.
	_rotation_input += (Input.get_action_raw_strength("camera_left") - Input.get_action_raw_strength("camera_right")) * joystick_sensitivity * delta
	_tilt_input += (Input.get_action_raw_strength("camera_up") - Input.get_action_raw_strength("camera_down")) * joystick_sensitivity * delta

	if invert_mouse_y:
		_tilt_input *= -1

	if _camera_raycast.is_colliding():
		_aim_target = _camera_raycast.get_collision_point()
		_aim_collider = _camera_raycast.get_collider()
	else:
		_aim_target = _camera_raycast.global_transform * _camera_raycast.target_position
		_aim_collider = null

	# Set camera controller to current ground level for the character
	var target_position := _anchor.global_position + _offset
	target_position.y = lerp(global_position.y, _anchor._ground_height, 0.1)
	global_position = target_position

	# Rotates camera using euler rotation. The inputs are already in radians
	# (mouse applied per-pixel, joystick already scaled by delta above), so
	# no delta here — multiplying mouse deltas by frame time made sensitivity
	# scale with FPS: 2.4x faster at 60fps than at 144fps.
	_euler_rotation.x += _tilt_input
	_euler_rotation.x = clamp(_euler_rotation.x, tilt_lower_limit, tilt_upper_limit)
	_euler_rotation.y += _rotation_input

	transform.basis = Basis.from_euler(_euler_rotation)

	camera.global_transform = _pivot.global_transform
	camera.rotation.z = 0

	_rotation_input = 0.0
	_tilt_input = 0.0


func setup(anchor: CharacterBody3D) -> void:
	_anchor = anchor
	# Discard any mouse motion accumulated before the anchor existed, so the
	# camera doesn't jump on the first controlled frame.
	_rotation_input = 0.0
	_tilt_input = 0.0
	global_transform = _anchor.global_transform
	_offset = global_transform.origin - anchor.global_transform.origin
	set_pivot(CAMERA_PIVOT.THIRD_PERSON)
	camera.global_transform = camera.global_transform.interpolate_with(_pivot.global_transform, 0.1)
	_camera_spring_arm.add_excluded_object(_anchor.get_rid())
	_camera_raycast.add_exception_rid(_anchor.get_rid())


func set_pivot(pivot_type: CAMERA_PIVOT) -> void:
	if pivot_type == _current_pivot_type:
		return

	match (pivot_type):
		CAMERA_PIVOT.OVER_SHOULDER:
			_over_shoulder_pivot.look_at(_aim_target)
			_pivot = _over_shoulder_pivot
		CAMERA_PIVOT.THIRD_PERSON:
			_pivot = _third_person_pivot

	_current_pivot_type = pivot_type


func get_aim_target() -> Vector3:
	return _aim_target


func get_aim_collider() -> Node:
	if is_instance_valid(_aim_collider):
		return _aim_collider
	else:
		return null
