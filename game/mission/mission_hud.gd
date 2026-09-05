class_name MissionHUD
extends CanvasLayer

const GameFlowScript := preload("res://game/mission/game_flow.gd")
const Catalog := preload("res://game/startups/startup_catalog.gd")

@onready var _timer_label: Label = $Root/TimerLabel
@onready var _objective_label: Label = $Root/ObjectiveLabel
@onready var _valuation_label: Label = $Root/ValuationLabel
@onready var _results: Control = $Root/Results
@onready var _results_title: Label = $Root/Results/Title
@onready var _results_body: Label = $Root/Results/Body
@onready var _minimap: Control = $Root/Minimap

var _flow: Node


func bind(flow: Node) -> void:
	_flow = flow
	if _minimap and _minimap.has_method("bind"):
		_minimap.bind(flow)
	if not flow.state_changed.is_connected(_on_state_changed):
		flow.state_changed.connect(_on_state_changed)
	if flow.has_signal("valuation_changed") and not flow.valuation_changed.is_connected(_on_valuation_changed):
		flow.valuation_changed.connect(_on_valuation_changed)
	_on_state_changed(flow.state)
	_on_valuation_changed(flow.valuation)


func _process(_delta: float) -> void:
	if _flow == null:
		return
	_timer_label.text = _format_timer()
	if _flow.state == GameFlowScript.State.SUCCESS or _flow.state == GameFlowScript.State.FAIL:
		if Input.is_action_just_pressed("jump"):
			get_tree().paused = false
			get_tree().reload_current_scene()


func _format_timer() -> String:
	if _flow.state == GameFlowScript.State.BRIEFING:
		return "--:--"
	if _flow.state == GameFlowScript.State.INFILTRATION:
		return _as_clock(_flow.timer.acquisition_remaining)
	return _as_clock(_flow.timer.escape_elapsed)


func _as_clock(seconds: float) -> String:
	var total := int(ceil(seconds))
	var minutes := int(total / 60.0)
	var secs := total % 60
	return "%d:%02d" % [minutes, secs]


func _on_valuation_changed(amount: int) -> void:
	if _valuation_label:
		_valuation_label.text = Catalog.format_valuation(amount)


func _on_state_changed(state: int) -> void:
	match state:
		GameFlowScript.State.BRIEFING:
			_objective_label.text = "Walk through the blue gate to start"
			_results.visible = false
		GameFlowScript.State.INFILTRATION:
			_objective_label.text = "Claim the gold throne"
			_results.visible = false
		GameFlowScript.State.ESCAPE:
			_objective_label.text = "Reach the green exit"
			_results.visible = false
		GameFlowScript.State.SUCCESS:
			_show_results("ESCAPED", true)
		GameFlowScript.State.FAIL:
			var title := "TIME UP" if _flow.fail_reason == "timeout" or _flow.timer.is_expired() else "KILLED"
			_show_results(title, false)


func _show_results(title: String, success: bool) -> void:
	_objective_label.text = "Escaped!" if success else ("Time up" if title == "TIME UP" else "Killed!")
	_results_title.text = title
	_results_body.text = "Acquire %s   Escape %s\nValuation %s\nPress A to retry" % [
		_as_clock(_flow.timer.acquisition_used),
		_as_clock(_flow.timer.escape_elapsed),
		Catalog.format_valuation(_flow.valuation),
	]
	_results.visible = true
	get_tree().paused = true
