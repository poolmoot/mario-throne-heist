# Mission Loop Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** Make `first_build` a complete acquire-and-escape run: start gate starts a 2-minute timer, walking onto the throne claims it, reaching the exit wins, timeout fails, results + retry.

**Architecture:** Pure `MissionTimer` (RefCounted) owns clock math. `GameFlow` (Node) owns states and wires Area3D triggers. HUD is a CanvasLayer that only displays flow signals. World markers are small scenes instanced in `game/first_build.tscn` on the existing KayKit city — no palace rebuild, no guards.

**Tech Stack:** Godot/Summer 4.7 GDScript, headless `SceneTree` tests via `/Applications/Summer.app/Contents/MacOS/Summer --headless --path … --script res://tests/….gd`

**Spec:** `docs/superpowers/specs/2026-09-05-mario-throne-heist-design.md` (Complete Flow items 4–9, minus stealth/lightsaber/menus)

## Global Constraints

- Viewport is exactly 800×480 with viewport stretch.
- Acquisition limit is 120 seconds; timer starts only after the start gate.
- Claiming the throne stops the acquisition timer and starts an escape stopwatch.
- Exit before a claim does nothing; exit after a claim succeeds.
- Acquisition timeout fails the run.
- Restart reloads `res://game/first_build.tscn`.
- Compatibility renderer; no new lights; simple collision shapes.
- Do not commit unless the user asks.

---

### Task 1: MissionTimer

**Files:**
- Create: `game/mission/mission_timer.gd`
- Test: `tests/test_mission_timer.gd`

**Produces:**
- `class_name MissionTimer`
- `const ACQUISITION_LIMIT := 120.0`
- `var acquisition_remaining: float`
- `var acquisition_used: float`
- `var escape_elapsed: float`
- `func start_infiltration() -> void`
- `func tick(delta: float) -> void`
- `func is_expired() -> bool`
- `func claim() -> void`

- [x] **Step 1: Write the failing test**

```gdscript
extends SceneTree

func _initialize() -> void:
	var timer := MissionTimer.new()
	if timer.acquisition_remaining != 120.0:
		push_error("fresh timer must be 120s")
		quit(1)
		return
	timer.start_infiltration()
	timer.tick(10.0)
	if abs(timer.acquisition_remaining - 110.0) > 0.001:
		push_error("tick should consume acquisition time")
		quit(1)
		return
	timer.claim()
	if timer.is_expired():
		push_error("claimed run is not expired")
		quit(1)
		return
	timer.tick(3.5)
	if abs(timer.escape_elapsed - 3.5) > 0.001:
		push_error("escape stopwatch should run after claim")
		quit(1)
		return
	if abs(timer.acquisition_used - 10.0) > 0.001:
		push_error("acquisition_used should freeze at claim")
		quit(1)
		return
	var failer := MissionTimer.new()
	failer.start_infiltration()
	failer.tick(120.0)
	if not failer.is_expired():
		push_error("120s of infiltration must expire")
		quit(1)
		return
	print("PASS: mission timer")
	quit()
```

- [x] **Step 2: Run test to verify it fails**

Run: `/Applications/Summer.app/Contents/MacOS/Summer --headless --path /Users/bamsefar/Projects/mario-throne-heist --script res://tests/test_mission_timer.gd`

Expected: parse/load error because `MissionTimer` does not exist.

- [x] **Step 3: Write minimal implementation** in `game/mission/mission_timer.gd`

- [x] **Step 4: Run test to verify it passes**

- [x] **Step 5: Do not commit** (user did not ask)

---

### Task 2: GameFlow states

**Files:**
- Create: `game/mission/game_flow.gd`
- Test: `tests/test_game_flow.gd`

**Consumes:** `MissionTimer`

**Produces:**
- `class_name GameFlow`
- `enum State { BRIEFING, INFILTRATION, ESCAPE, SUCCESS, FAIL }`
- `var state: State`
- `var timer: MissionTimer`
- `func crossed_start_gate() -> void`
- `func stepped_on_throne() -> void`
- `func reached_exit() -> void`
- `func process_time(delta: float) -> void`

Rules:
- Start in `BRIEFING`; gate → `INFILTRATION` and `timer.start_infiltration()`.
- Duplicate gate entries do nothing.
- Throne in `INFILTRATION` → `claim()` and `ESCAPE`.
- Throne in any other state does nothing.
- Exit in `ESCAPE` → `SUCCESS`.
- Exit before claim does nothing.
- `process_time` during `INFILTRATION` that expires → `FAIL`.
- `process_time` after `FAIL`/`SUCCESS` does not change state.

- [x] **Step 1: Write failing `tests/test_game_flow.gd` covering the rules above**

- [x] **Step 2: Run it (expect missing `GameFlow`)**

- [x] **Step 3: Implement `game_flow.gd` as a Node with those methods (no Area3D required for the test)**

- [x] **Step 4: Re-run until PASS**

---

### Task 3: World markers + HUD + first_build

**Files:**
- Create: `game/mission/start_gate.tscn`, `game/mission/throne.tscn`, `game/mission/exit_zone.tscn`
- Create: `game/mission/mission_hud.gd`, `game/mission/mission_hud.tscn`
- Modify: `game/first_build.tscn`
- Modify: `game/mission/game_flow.gd` to connect areas and follow the player with the claimed throne visual

**World placement (city root scale 4, player at `(0, 0.55, -16)`):**
- Start gate: `(0, 1.0, -10)` — a few metres ahead of spawn
- Throne: `(8, 0.0, 8)` — plaza
- Exit: `(0, 0.5, 36)` — south along the central avenue

Each marker is an `Area3D` (`collision_mask = 1`, `monitoring = true`) with a visible mesh so it reads at 800×480.

HUD (CanvasLayer, 800×480):
- Large center-top timer (`MM:SS` of `acquisition_remaining` during infiltration, `escape_elapsed` during escape, `--:--` in briefing)
- Objective label: `Reach the gate` / `Claim the throne` / `Escape` / `Escaped!` / `Time up`
- Results panel on SUCCESS/FAIL: acquisition used, escape time, `Jump to retry`
- `process_mode = PROCESS_MODE_ALWAYS`; pause the tree on SUCCESS/FAIL; Jump reloads the current scene

`GameFlow._physics_process` calls `process_time(delta)` and, while `ESCAPE`/`SUCCESS`, keeps the throne mesh above Mario's head (`player.global_position + Vector3(0, 2.2, 0)`).

- [x] **Step 1: Add `tests/test_mission_loop_scene.gd`** that instances `first_build`, finds StartGate/Throne/Exit/HUD, and asserts they exist

- [x] **Step 2: Run (expect missing nodes)**

- [x] **Step 3: Add scenes, HUD, wire `first_build`**

- [x] **Step 4: Run scene test + existing `test_first_build.gd` / `test_mario_scale.gd` / `test_mario_anim.gd`**

- [x] **Step 5: `summer_play`, screenshot briefing, verify timer does not run until gate**

---

## Spec coverage

| Spec item | This plan |
|---|---|
| Timer starts at start gate | Task 2–3 |
| 2-minute acquisition | Task 1 |
| Walk onto throne claims it; visual follows | Task 2–3 |
| Escape timer for scoring | Task 1–3 |
| Reach exit to complete | Task 2–3 |
| Timeout fail | Task 1–2 |
| Results + retry | Task 3 |
| Title, light cal, disguise, lightsaber, guards, lockdown drawbridge | Out of scope (next slices) |
