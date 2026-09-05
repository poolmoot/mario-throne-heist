extends CharacterBody3D

const BOLT_SCENE := preload("res://game/weapons/blaster_bolt.tscn")
const GameFlowScript := preload("res://game/mission/game_flow.gd")

@export var patrol_to := Vector3(0, 0, 10)
@export var walk_speed := 3.2
@export var detect_range := 16.0
@export var shoot_interval := 1.25
@export var bolt_speed := 20.0

@onready var _visual: Node3D = $Visual
@onready var _ray: RayCast3D = $Sight

var _home := Vector3.ZERO
var _goal := Vector3.ZERO
var _out := true
var _shoot_cd := 0.0
var _player: Node3D
var _gravity: float = 30.0


func _ready() -> void:
	add_to_group("troopers")
	_home = global_position
	_goal = global_position + patrol_to
	_player = get_tree().get_first_node_in_group("damageables") as Node3D
	_play_visual("idle")


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= _gravity * delta
	else:
		velocity.y = 0.0

	_shoot_cd = maxf(0.0, _shoot_cd - delta)
	if _can_fight() and _sees_player():
		_combat(delta)
	else:
		_patrol(delta)
	move_and_slide()


func _can_fight() -> bool:
	var flow := get_tree().get_first_node_in_group("game_flow")
	if flow == null:
		return false
	return flow.state == GameFlowScript.State.INFILTRATION or flow.state == GameFlowScript.State.ESCAPE


func _sees_player() -> bool:
	if _player == null or not is_instance_valid(_player):
		return false
	if global_position.distance_to(_player.global_position) > detect_range:
		return false
	_ray.target_position = _ray.to_local(_player.global_position + Vector3(0, 1.1, 0))
	_ray.force_raycast_update()
	if not _ray.is_colliding():
		return true
	return _ray.get_collider() == _player


func _combat(_delta: float) -> void:
	var to_player := _player.global_position - global_position
	to_player.y = 0.0
	if to_player.length() > 0.15:
		_face(to_player)
	velocity.x = 0.0
	velocity.z = 0.0
	_play_visual("shoot")
	if _shoot_cd <= 0.0:
		_fire(to_player)
		_shoot_cd = shoot_interval


func _patrol(_delta: float) -> void:
	var target := _goal if _out else _home
	var offset := target - global_position
	offset.y = 0.0
	if offset.length() < 0.6:
		_out = not _out
		_play_visual("idle")
		velocity.x = 0.0
		velocity.z = 0.0
		return
	_face(offset)
	var dir := offset.normalized()
	velocity.x = dir.x * walk_speed
	velocity.z = dir.z * walk_speed
	_play_visual("walk")


func _fire(forward: Vector3) -> void:
	var dir := forward.normalized()
	if dir.length_squared() < 0.01:
		dir = -global_transform.basis.z
	var bolt := BOLT_SCENE.instantiate() as Area3D
	bolt.shooter = self
	bolt.velocity = dir * bolt_speed
	var host := get_tree().current_scene
	if host == null:
		host = get_parent()
	host.add_child(bolt)
	bolt.global_position = global_position + Vector3(0, 1.8, 0) + dir * 1.4


func _face(direction: Vector3) -> void:
	if direction.length_squared() < 0.0001:
		return
	var look := global_position + direction
	look.y = global_position.y
	look_at(look, Vector3.UP)


func _play_visual(clip: String) -> void:
	if _visual and _visual.has_method("play_clip"):
		_visual.play_clip(clip)
