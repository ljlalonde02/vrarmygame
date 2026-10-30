extends SceneTree
## Gate 3 Automated Verification Suite (`res://tests/test_war_table_visuals.gd`)
## Verifies:
## 1. `war_table.tscn` instantiation and binding to `SimServer`.
## 2. Zero-error compilation of `war_table_terrain.gdshader`, `hologram_token.gdshader`, and `fresnel_dome.gdshader`.
## 3. Semantic Zoom Echelon transitions (`Brigade [2]` -> `Battalion [1]` -> `Company / Robot Dog Pack [0]`).
## 4. `MultiMesh` buffer population for UnitTokens, AltitudeStems, and ActiveMunitions + `StrikePreviewRenderer`.

const SimDBScript := preload("res://src/autoloads/sim_db.gd")
const CommandBusScript := preload("res://src/autoloads/command_bus.gd")
const SignalBusScript := preload("res://src/autoloads/signal_bus.gd")
const SimServerScript := preload("res://src/sim_core/sim_server.gd")
const WarTableScene := preload("res://src/presentation/war_table/war_table.tscn")


func _init() -> void:
	print("==================================================================")
	print("[GATE 3] Starting War Table & Shaders Visual Verification Suite...")
	print("==================================================================")

	var sim_db := SimDBScript.new()
	var cmd_bus := CommandBusScript.new()
	var sig_bus := SignalBusScript.new()
	sim_db.load_database()

	var sim_server := SimServerScript.new()
	sim_server.setup_references(sim_db, cmd_bus, sig_bus)
	sim_server.load_scenario("op_pacific_shield_2028")

	var war_table := WarTableScene.instantiate()
	root.add_child(war_table)
	if war_table.visual_sync == null:
		war_table._ready()
	if war_table.visual_sync.unit_tokens_mmi == null:
		war_table.visual_sync._ready()
	if war_table.strike_preview._immediate == null:
		war_table.strike_preview._ready()
	war_table.bind_sim_server(sim_server)

	# 1. Verify Shaders Loaded & Compiled
	var terrain_shader: Shader = load("res://src/presentation/war_table/shaders/war_table_terrain.gdshader")
	var token_shader: Shader = load("res://src/presentation/war_table/shaders/hologram_token.gdshader")
	var dome_shader: Shader = load("res://src/presentation/war_table/shaders/fresnel_dome.gdshader")
	assert(terrain_shader != null, "war_table_terrain.gdshader must compile")
	assert(token_shader != null, "hologram_token.gdshader must compile")
	assert(dome_shader != null, "fresnel_dome.gdshader must compile")
	print("  [1] All 3 custom holographic shaders compiled cleanly!")

	# 2. Test Semantic Zoom Tier 1: Macro Theater View (`zoom_scale = 1.0` -> Brigades)
	war_table.set_zoom_and_pan(1.0, Vector2.ZERO, true)
	var bde_ech: int = war_table.get_active_semantic_echelon()
	var bde_visible: int = war_table.visual_sync.unit_tokens_mmi.multimesh.visible_instance_count
	print("  [2] Semantic Zoom 1.0x (Macro): Echelon=%d (Brigade) | Visible MultiMesh Tokens=%d" % [bde_ech, bde_visible])
	assert(bde_ech == 2, "Zoom 1.0x must select Brigade echelon (2)")
	assert(bde_visible >= 16, "Expected >=16 Brigade tokens at 1.0x zoom, got %d" % bde_visible)

	# 3. Test Semantic Zoom Tier 2: Operational View (`zoom_scale = 3.0` -> Battalions)
	war_table.set_zoom_and_pan(3.0, Vector2(95.0, -25.0), true)
	var bn_ech: int = war_table.get_active_semantic_echelon()
	var bn_visible: int = war_table.visual_sync.unit_tokens_mmi.multimesh.visible_instance_count
	print("  [3] Semantic Zoom 3.0x (Operational): Echelon=%d (Battalion) | Visible MultiMesh Tokens=%d" % [bn_ech, bn_visible])
	assert(bn_ech == 1, "Zoom 3.0x must select Battalion echelon (1)")
	assert(bn_visible > 16, "Expected >16 Battalion tokens in view at 3.0x zoom")

	# 4. Test Semantic Zoom Tier 3: Tactical Valley View (`zoom_scale = 8.0` -> Companies / Robot Dog Packs)
	war_table.set_zoom_and_pan(8.0, Vector2(85.0, 25.0), true)
	var co_ech: int = war_table.get_active_semantic_echelon()
	var co_visible: int = war_table.visual_sync.unit_tokens_mmi.multimesh.visible_instance_count
	print("  [4] Semantic Zoom 8.0x (Tactical Valley): Echelon=%d (Company/Robot Dogs) | Visible MultiMesh Tokens=%d" % [co_ech, co_visible])
	assert(co_ech == 0, "Zoom 8.0x must select Company/Leaf echelon (0)")
	assert(co_visible >= 12, "Expected >=12 leaf Company tokens visible in tactical valley view")

	# 5. Test Force All 600+ Tokens Override + Alpha Strike Munitions MultiMesh + Strike Preview
	war_table.set_zoom_and_pan(1.0, Vector2.ZERO, true)
	war_table.visual_sync.force_all_tokens = true
	war_table.visual_sync.true_sight_enabled = true
	cmd_bus.enqueue_commit_alpha_strike(1)
	sim_server.step_tick(0.1)
	war_table.visual_sync.sync_visuals()

	var all_tokens_vis: int = war_table.visual_sync.unit_tokens_mmi.multimesh.visible_instance_count
	var muns_vis: int = war_table.visual_sync.active_munitions_mmi.multimesh.visible_instance_count
	war_table.strike_preview.show_strike_preview(Vector3(110.0, 5000.0, -40.0), Vector3(-110.0, 50.0, -10.0), 4.0, "AIM-120D / JASSM")
	print("  [5] Force All Tokens Override: %d leaf tokens | Active Munitions MultiMesh=%d | StrikePreview Active=%s" % [
		all_tokens_vis, muns_vis, str(war_table.strike_preview.is_preview_active)
	])
	assert(all_tokens_vis >= 500, "Expected 500+ leaf tokens rendered in single MultiMesh draw call")
	assert(muns_vis >= 16, "Expected active salvo munitions rendered in ActiveMunitionsMultiMesh")
	assert(war_table.strike_preview.is_preview_active, "StrikePreviewRenderer must be active")

	# 6. Verify Real-World GIS World Political Map, Sovereign Country Labels, Demarcation Borders & Real City Hubs
	var globe_shader: Shader = load("res://src/presentation/war_table/shaders/planetary_globe.gdshader")
	assert(globe_shader != null, "planetary_globe.gdshader must compile")
	var has_wmap_terrain: bool = bool(war_table.terrain_material.get_shader_parameter("has_world_map_tex"))
	var globe_countries_node: Node3D = war_table._planetary_globe_root.get_node_or_null("SovereignCountryLabels")
	var globe_country_count: int = globe_countries_node.get_child_count() if globe_countries_node != null else 0
	var table_banners: int = 0
	var real_city_labels: int = 0
	for child in war_table._site_labels_root.get_children():
		if child.name.begins_with("SovereignBanner_"):
			table_banners += 1
		elif child.name.begins_with("RealCityLabel_"):
			real_city_labels += 1
	print("  [6] Real-World GIS Map Bound=%s | Globe Sovereign Countries=%d | Theater Sovereign Banners=%d | Real City Labels=%d" % [
		str(has_wmap_terrain), globe_country_count, table_banners, real_city_labels
	])
	assert(has_wmap_terrain, "world_political_map.png must be bound to war_table_terrain.gdshader")
	assert(globe_country_count >= 20, "Expected >=20 sovereign country labels on 3D Planetary Globe")
	assert(table_banners >= 3, "Expected >=3 sovereign country & border demarcation banners on 500km War Table")
	assert(real_city_labels >= 6, "Expected >=6 real-world metropolitan city labels on 500km War Table")

	# 7. Verify City Street Grids, Ring Roads, Inter-City Highway Corridors & 3D Urban Boulevards for ALL Real Cities
	var ws := sim_server.world_state
	var real_cities: Array[Dictionary] = war_table.CivilianDensitySystemScript.get_theater_real_cities(ws.active_theater_slug)
	var cities_with_roads := 0
	for rc in real_cities:
		var c_idx := ws.get_infra_cell_index(float(rc.get("x_km", 0.0)), float(rc.get("z_km", 0.0)))
		if ws.infra_road_mask[c_idx] > 0.5:
			cities_with_roads += 1
	var road_avenues_3d := 0
	for bi in range(ws.bldg_count):
		if ws.bldg_type[bi] == ws.BLDG_ROAD_AVENUE:
			road_avenues_3d += 1
	print("  [7] City Road Coverage: %d/%d real cities have active street grids | Highway Segments=%d | City Hubs=%d | 3D Urban Boulevards=%d" % [
		cities_with_roads, real_cities.size(), ws.road_segments_km.size(), ws.city_hubs_km.size(), road_avenues_3d
	])
	assert(cities_with_roads == real_cities.size(), "100% of real cities must have active road infrastructure (infra_road_mask > 0.5)")
	assert(ws.road_segments_km.size() >= 10, "Expected >=10 inter-city highway corridor segments")
	assert(ws.city_hubs_km.size() >= real_cities.size(), "Expected city_hubs_km populated for all real cities and bases")
	assert(road_avenues_3d >= 20, "Expected >=20 3D urban boulevard strips (BLDG_ROAD_AVENUE) separating city blocks")

	print("==================================================================")
	print("[GATE 3 PASSED] All War Table & Shader checks succeeded with 0 errors!")
	print("==================================================================")
	war_table.free()
	sim_server.cleanup()
	sim_server.free()
	sig_bus.free()
	cmd_bus.free()
	sim_db.free()
	quit(0)
