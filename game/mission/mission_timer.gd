class_name MissionTimer
extends RefCounted

const ACQUISITION_LIMIT := 120.0

var acquisition_remaining := ACQUISITION_LIMIT
var acquisition_used := 0.0
var escape_elapsed := 0.0
var infiltration_running := false
var escape_running := false


func start_infiltration() -> void:
	infiltration_running = true
	escape_running = false
	acquisition_remaining = ACQUISITION_LIMIT
	acquisition_used = 0.0
	escape_elapsed = 0.0


func tick(delta: float) -> void:
	if infiltration_running:
		acquisition_remaining = maxf(0.0, acquisition_remaining - delta)
	if escape_running:
		escape_elapsed += delta


func is_expired() -> bool:
	return infiltration_running and acquisition_remaining <= 0.0


func claim() -> void:
	if not infiltration_running:
		return
	infiltration_running = false
	escape_running = true
	acquisition_used = ACQUISITION_LIMIT - acquisition_remaining
