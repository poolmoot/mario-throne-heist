extends SceneTree

const Catalog := preload("res://game/startups/startup_catalog.gd")
const GameFlowScript := preload("res://game/mission/game_flow.gd")


func _initialize() -> void:
	if Catalog.format_valuation(0) != "0k":
		push_error("0 should format as 0k, got %s" % Catalog.format_valuation(0))
		quit(1)
		return
	if Catalog.format_valuation(500_000) != "500k":
		push_error("500000 should format as 500k, got %s" % Catalog.format_valuation(500_000))
		quit(1)
		return
	if Catalog.format_valuation(2_400_000) != "2.4M":
		push_error("2400000 should format as 2.4M, got %s" % Catalog.format_valuation(2_400_000))
		quit(1)
		return

	var flow = GameFlowScript.new()
	if flow.valuation != 0:
		push_error("valuation must start at 0")
		quit(1)
		return
	flow.collect_startup(500_000)
	if flow.valuation != 500_000:
		push_error("collect should add valuation, got %s" % flow.valuation)
		quit(1)
		return
	flow.collect_startup(2_400_000)
	if flow.valuation != 2_900_000:
		push_error("valuation should accumulate, got %s" % flow.valuation)
		quit(1)
		return

	var hud_packed := load("res://game/mission/mission_hud.tscn") as PackedScene
	var hud := hud_packed.instantiate()
	root.add_child(hud)
	await process_frame
	var label := hud.get_node_or_null("Root/ValuationLabel") as Label
	if label == null:
		push_error("HUD is missing top-right ValuationLabel")
		quit(1)
		return

	print("PASS: valuation formats and accumulates")
	quit()
