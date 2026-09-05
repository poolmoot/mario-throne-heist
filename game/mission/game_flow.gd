class_name GameFlow
extends Node

enum State { BRIEFING, INFILTRATION, ESCAPE, SUCCESS, FAIL }

signal state_changed(state: int)
signal valuation_changed(amount: int)

const MissionTimerScript := preload("res://game/mission/mission_timer.gd")
const THRONE_FOLLOW_OFFSET := Vector3(0, 2.2, 0)

@export var player_path: NodePath = ^"../Player"

var state: State = State.BRIEFING
var timer = MissionTimerScript.new()
var player: Node3D
var _throne: Area3D
var fail_reason := ""
var valuation := 0


func _ready() -> void:
	add_to_group("game_flow")
	player = get_node_or_null(player_path) as Node3D
	_throne = get_node_or_null("Throne") as Area3D
	var gate := get_node_or_null("StartGate") as Area3D
	var exit := get_node_or_null("ExitZone") as Area3D
	if gate:
		gate.body_entered.connect(_on_gate_body)
	if _throne:
		_throne.body_entered.connect(_on_throne_body)
	if exit:
		exit.body_entered.connect(_on_exit_body)
	var hud := get_node_or_null("HUD")
	if hud and hud.has_method("bind"):
		hud.bind(self)
	if player and player.has_signal("died"):
		player.died.connect(player_died)


func _physics_process(delta: float) -> void:
	process_time(delta)
	if (state == State.ESCAPE or state == State.SUCCESS) and player and _throne:
		_throne.global_position = player.global_position + THRONE_FOLLOW_OFFSET


func _on_gate_body(body: Node3D) -> void:
	if body == player:
		crossed_start_gate()


func _on_throne_body(body: Node3D) -> void:
	if body != player:
		return
	stepped_on_throne()
	if _throne:
		_throne.set_deferred("monitoring", false)


func _on_exit_body(body: Node3D) -> void:
	if body == player:
		reached_exit()


func collect_startup(amount: int) -> void:
	valuation += amount
	valuation_changed.emit(valuation)


func crossed_start_gate() -> void:
	if state != State.BRIEFING:
		return
	timer.start_infiltration()
	_set_state(State.INFILTRATION)


func stepped_on_throne() -> void:
	if state != State.INFILTRATION:
		return
	timer.claim()
	_set_state(State.ESCAPE)


func reached_exit() -> void:
	if state != State.ESCAPE:
		return
	_set_state(State.SUCCESS)


func player_died() -> void:
	if state != State.INFILTRATION and state != State.ESCAPE:
		return
	fail_reason = "killed"
	_set_state(State.FAIL)


func spotted() -> void:
	player_died()


func process_time(delta: float) -> void:
	if state != State.INFILTRATION and state != State.ESCAPE:
		return
	timer.tick(delta)
	if state == State.INFILTRATION and timer.is_expired():
		fail_reason = "timeout"
		_set_state(State.FAIL)


func _set_state(next: State) -> void:
	if state == next:
		return
	state = next
	state_changed.emit(state)
