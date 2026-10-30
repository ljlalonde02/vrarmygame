class_name WarTable
extends Node3D
## The 1.8m x 1.8m Holographic Sand Table representing the 500 km x 500 km theater.
## Manages:
## - Displaced holographic terrain mesh (`war_table_terrain.gdshader`)
## - Translucent Fresnel SAM & HPM threat domes (`fresnel_dome.gdshader`)
## - Semantic Zoom (`zoom_scale` 1.0x -> 25.0x: Brigade -> Battalion -> Company / Robot Dog Pack)
## - Coordinate conversion between 3D Bunker space and 500km Theater coordinates.

const VisualSyncScript := preload("res://src/presentation/war_table/visual_sync_controller.gd")
const StrikePreviewScript := preload("res://src/presentation/war_table/strike_preview_renderer.gd")
const CivilianDensitySystemScript := preload("res://src/sim_core/systems/civilian_density_system.gd")

const TABLE_SIZE_M := 1.80
const THEATER_SIZE_KM := 500.0
const ALTITUDE_M_TO_TABLE_M := 0.000032 # Tacview 3D vertical scale: 10,000m altitude = 0.32m above table surface

var sim_server: Node = null
var visual_sync: Node3D = null
var strike_preview: Node3D = null

var zoom_scale: float = 1.0
var target_zoom_scale: float = 1.0
var pan_offset_km: Vector2 = Vector2.ZERO
var target_pan_offset_km: Vector2 = Vector2.ZERO
var graphic_style_mode: int = 0

const GRAPHIC_STYLE_NAMES: Array[String] = [
	"HOLO C4ISR OBSIDIAN",
	"SATELLITE TRUE-EARTH DAYLIGHT",
	"NIGHT-VISION FLIR GREEN",
	"RETRO NORAD WOPR AMBER",
	"NATO TOPOGRAPHIC MAP",
]

var terrain_mesh_instance: MeshInstance3D = null
var terrain_material: ShaderMaterial = null
var _threat_domes_root: Node3D = null
var _site_labels_root: Node3D = null
var _planetary_globe_root: Node3D = null


func _ready() -> void:
	_build_table_geometry()
	_setup_controllers()


func bind_sim_server(p_sim_server: Node) -> void:
	sim_server = p_sim_server
	if visual_sync != null:
		visual_sync.sim_server = p_sim_server
		visual_sync.sim_db = p_sim_server.sim_db_ref
		visual_sync.war_table = self
	if strike_preview != null:
		strike_preview.war_table = self
	_rebuild_strategic_site_markers_and_domes()
	if visual_sync != null:
		visual_sync.sync_visuals()


func _build_table_geometry() -> void:
	if terrain_mesh_instance != null:
		return

	# 1. Heavy Obsidian Metallic Pedestal & Bezel Frame
	var pedestal := MeshInstance3D.new()
	pedestal.name = "TablePedestal"
	var ped_box := BoxMesh.new()
	ped_box.size = Vector3(1.94, 0.86, 1.94)
	var ped_mat := StandardMaterial3D.new()
	ped_mat.albedo_color = Color(0.035, 0.05, 0.075, 1.0)
	ped_mat.metallic = 0.75
	ped_mat.roughness = 0.32
	ped_box.material = ped_mat
	pedestal.mesh = ped_box
	pedestal.position = Vector3(0.0, -0.44, 0.0)
	add_child(pedestal)

	# Dark Obsidian Well Floor + Thin Cyan Perimeter Bezel around the 1.8m x 1.8m Hologram Well
	var rim := MeshInstance3D.new()
	rim.name = "TableCyanRim"
	var rim_box := BoxMesh.new()
	rim_box.size = Vector3(1.86, 0.015, 1.86)
	var rim_mat := StandardMaterial3D.new()
	rim_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rim_mat.albedo_color = Color(0.015, 0.025, 0.045, 1.0)
	rim_box.material = rim_mat
	rim.mesh = rim_box
	rim.position = Vector3(0.0, -0.008, 0.0)
	add_child(rim)

	# 2. Displaced Topographic & Bathymetric Terrain Mesh (128x128 on PC, 64x64 on Mobile VR)
	terrain_mesh_instance = MeshInstance3D.new()
	terrain_mesh_instance.name = "HologramTerrainMesh"
	var plane := PlaneMesh.new()
	plane.size = Vector2(TABLE_SIZE_M, TABLE_SIZE_M)
	var subdiv := 64 if OS.has_feature("android") else 128
	plane.subdivide_width = subdiv
	plane.subdivide_depth = subdiv

	terrain_material = ShaderMaterial.new()
	terrain_material.shader = load("res://src/presentation/war_table/shaders/war_table_terrain.gdshader")
	var hmap_path := "res://data/theaters/strait_theater_heightmap.png"
	if ResourceLoader.exists(hmap_path):
		terrain_material.set_shader_parameter("heightmap_tex", load(hmap_path))
	elif not OS.has_feature("android"):
		var hmap_global := ProjectSettings.globalize_path(hmap_path)
		var h_img := Image.new()
		if FileAccess.file_exists(hmap_global) and h_img.load(hmap_global) == OK:
			terrain_material.set_shader_parameter("heightmap_tex", ImageTexture.create_from_image(h_img))

	# Load Real-World GIS Geopolitical & Topographic World Map (`world_political_map.png`)
	var world_map_tex: Texture2D = _load_world_political_map_texture()
	if world_map_tex != null:
		terrain_material.set_shader_parameter("world_map_tex", world_map_tex)
		terrain_material.set_shader_parameter("has_world_map_tex", true)

	plane.material = terrain_material
	terrain_mesh_instance.mesh = plane
	add_child(terrain_mesh_instance)

	# 3. Threat Domes & Strategic Site Hologram Labels Roots
	_threat_domes_root = Node3D.new()
	_threat_domes_root.name = "FresnelThreatDomes"
	add_child(_threat_domes_root)

	_site_labels_root = Node3D.new()
	_site_labels_root.name = "StrategicSiteLabels"
	add_child(_site_labels_root)

	# 4. 3D Holographic Planetary Globe (Visible at Zoom < 0.42x Planetary Orbital View)
	_planetary_globe_root = Node3D.new()
	_planetary_globe_root.name = "PlanetaryHologramGlobe"
	_planetary_globe_root.position = Vector3(0.0, 0.42, 0.0)
	_planetary_globe_root.rotation.y = deg_to_rad(-175.0) # Face Eurasia, Middle East & Indo-Pacific (85E) toward +Z camera
	_planetary_globe_root.visible = false
	add_child(_planetary_globe_root)

	var globe_mi := MeshInstance3D.new()
	globe_mi.name = "GlobeSphereMesh"
	var globe_sph := SphereMesh.new()
	globe_sph.radius = 0.44
	globe_sph.height = 0.88
	globe_sph.radial_segments = 64
	globe_sph.rings = 32
	var globe_mat := ShaderMaterial.new()
	globe_mat.shader = load("res://src/presentation/war_table/shaders/planetary_globe.gdshader")
	if world_map_tex != null:
		globe_mat.set_shader_parameter("world_map_tex", world_map_tex)
		globe_mat.set_shader_parameter("has_world_map_tex", true)
	globe_sph.material = globe_mat
	globe_mi.mesh = globe_sph
	_planetary_globe_root.add_child(globe_mi)

	# 3D Keplerian Orbital Track Rings around the Planetary Globe
	var ring_inclinations := [
		[48.0, 0.0, Color(0.0, 0.85, 1.0, 0.55), 0.54],
		[62.0, 60.0, Color(1.0, 0.22, 0.35, 0.50), 0.56],
		[55.0, 120.0, Color(1.0, 0.78, 0.20, 0.48), 0.60],
		[72.0, 180.0, Color(0.45, 0.95, 1.0, 0.45), 0.52],
	]
	for r_info in ring_inclinations:
		var ring_mi := MeshInstance3D.new()
		var torus := TorusMesh.new()
		var r_rad: float = float(r_info[3])
		torus.inner_radius = r_rad - 0.0025
		torus.outer_radius = r_rad + 0.0025
		torus.rings = 48
		torus.ring_segments = 8
		var r_mat := StandardMaterial3D.new()
		r_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		r_mat.albedo_color = r_info[2]
		r_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		torus.material = r_mat
		ring_mi.mesh = torus
		ring_mi.rotation = Vector3(deg_to_rad(float(r_info[0])), deg_to_rad(float(r_info[1])), 0.0)
		_planetary_globe_root.add_child(ring_mi)

	# Pin all 7 Global Flashpoint Theaters (1,000,000 Total Units) onto the 3D Planetary Globe at their real Lat/Lon coordinates
	var flashpoints := [
		["OP 1-2: CHINA / TAIWAN STRAIT [220k UNITS]", 24.0, 120.0, Color(0.0, 0.92, 1.0), "op_pacific_shield_2028"],
		["OP 3: STRAIT OF HORMUZ [50k UNITS]", 26.0, 56.0, Color(1.0, 0.76, 0.18), "op_red_strait_swarm"],
		["OP 4: KOREAN DMZ [110k UNITS]", 38.0, 127.0, Color(0.35, 0.95, 1.0), "op_korean_thunder_dmz"],
		["OP 5: NATO BALTIC SUWALKI [160k UNITS]", 54.0, 23.0, Color(0.45, 0.85, 1.0), "op_baltic_shield_suwalki"],
		["OP 6: INDIA HIMALAYA LAC [150k UNITS]", 34.0, 78.0, Color(1.0, 0.45, 0.25), "op_himalayan_sentinel_lac"],
		["OP 7: UKRAINE DONBAS & BLACK SEA [240k UNITS]", 48.0, 35.5, Color(1.0, 0.88, 0.22), "op_ukraine_donbas_2028"],
		["OP 8: US-MEXICO RIO GRANDE [70k UNITS]", 26.2, -99.2, Color(0.30, 0.95, 0.68), "op_mexico_rio_grande_2028"],
	]
	for fp in flashpoints:
		var fp_name: String = String(fp[0])
		var lat_r := deg_to_rad(float(fp[1]))
		var lon_r := deg_to_rad(float(fp[2]))
		var fp_col: Color = fp[3]
		var fp_slug: String = String(fp[4])
		var surf_dir := Vector3(cos(lat_r) * cos(lon_r), sin(lat_r), -cos(lat_r) * sin(lon_r))

		# Glowing surface beacon sphere + radial stalk
		var beacon_mi := MeshInstance3D.new()
		beacon_mi.name = "GlobeBeacon_" + fp_slug
		var b_sph := SphereMesh.new()
		b_sph.radius = 0.016
		b_sph.height = 0.032
		var b_mat := StandardMaterial3D.new()
		b_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		b_mat.albedo_color = fp_col
		b_sph.material = b_mat
		beacon_mi.mesh = b_sph
		beacon_mi.position = surf_dir * 0.448
		beacon_mi.set_meta("scenario_slug", fp_slug)
		_planetary_globe_root.add_child(beacon_mi)

		var fp_lbl := Label3D.new()
		fp_lbl.text = "* " + fp_name
		fp_lbl.font_size = 18
		fp_lbl.pixel_size = 0.00072
		fp_lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		fp_lbl.modulate = fp_col
		fp_lbl.position = surf_dir * 0.495
		_planetary_globe_root.add_child(fp_lbl)

	# Pin Sovereign Country & World Capital C4ISR Labels across the 3D Planetary Globe
	var globe_countries_root := Node3D.new()
	globe_countries_root.name = "SovereignCountryLabels"
	_planetary_globe_root.add_child(globe_countries_root)
	var sovereign_nations := [
		["UNITED STATES [WASHINGTON / FORT CAVAZOS]", 39.0, -98.0, Color(0.35, 0.90, 1.0, 0.90)],
		["MEXICO [MEXICO CITY / MONTERREY SEDENA]", 22.5, -101.5, Color(0.30, 0.92, 0.68, 0.90)],
		["CANADA [OTTAWA]", 56.0, -106.0, Color(0.35, 0.88, 1.0, 0.82)],
		["BRAZIL [BRASILIA]", -14.0, -52.0, Color(0.28, 0.88, 0.68, 0.82)],
		["UNITED KINGDOM [LONDON]", 54.0, -2.0, Color(0.35, 0.90, 1.0, 0.88)],
		["FRANCE [PARIS]", 46.5, 2.2, Color(0.35, 0.90, 1.0, 0.88)],
		["GERMANY [BERLIN]", 51.2, 10.4, Color(0.35, 0.90, 1.0, 0.88)],
		["POLAND [WARSAW]", 52.0, 19.2, Color(0.35, 0.90, 1.0, 0.90)],
		["UKRAINE [KYIV]", 49.0, 31.5, Color(0.95, 0.84, 0.38, 0.88)],
		["RUSSIAN FEDERATION [MOSCOW]", 61.0, 68.0, Color(1.0, 0.36, 0.48, 0.92)],
		["TURKEY [ANKARA]", 39.0, 35.0, Color(0.38, 0.88, 0.92, 0.88)],
		["EGYPT [CAIRO]", 27.0, 30.0, Color(0.28, 0.88, 0.68, 0.80)],
		["SAUDI ARABIA [RIYADH]", 24.0, 45.0, Color(0.28, 0.88, 0.68, 0.85)],
		["I.R. IRAN [TEHRAN]", 32.5, 53.5, Color(1.0, 0.36, 0.48, 0.90)],
		["PAKISTAN [ISLAMABAD]", 30.5, 69.5, Color(0.32, 0.88, 0.72, 0.88)],
		["INDIA [NEW DELHI]", 22.5, 79.0, Color(0.32, 0.92, 0.75, 0.92)],
		["P.R. CHINA [BEIJING]", 36.5, 104.0, Color(1.0, 0.36, 0.48, 0.92)],
		["MONGOLIA [ULAANBAATAR]", 46.8, 103.5, Color(0.88, 0.80, 0.42, 0.80)],
		["DPR KOREA [PYONGYANG]", 40.2, 127.0, Color(1.0, 0.36, 0.48, 0.90)],
		["ROK SOUTH KOREA [SEOUL]", 36.2, 128.0, Color(0.35, 0.90, 1.0, 0.90)],
		["ROC TAIWAN [TAIPEI]", 23.7, 121.0, Color(0.35, 0.92, 1.0, 0.92)],
		["JAPAN [TOKYO]", 36.5, 138.5, Color(0.35, 0.90, 1.0, 0.90)],
		["PHILIPPINES [MANILA]", 13.0, 122.0, Color(0.35, 0.88, 1.0, 0.84)],
		["INDONESIA [JAKARTA]", -2.5, 118.0, Color(0.28, 0.88, 0.68, 0.82)],
		["AUSTRALIA [CANBERRA]", -25.0, 134.0, Color(0.35, 0.90, 1.0, 0.88)],
	]
	for sn in sovereign_nations:
		var c_lat_r := deg_to_rad(float(sn[1]))
		var c_lon_r := deg_to_rad(float(sn[2]))
		var c_dir := Vector3(cos(c_lat_r) * cos(c_lon_r), sin(c_lat_r), -cos(c_lat_r) * sin(c_lon_r))
		var c_lbl := Label3D.new()
		c_lbl.text = String(sn[0])
		c_lbl.font_size = 14
		c_lbl.pixel_size = 0.00058
		c_lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		c_lbl.modulate = sn[3]
		c_lbl.position = c_dir * 0.462
		globe_countries_root.add_child(c_lbl)


func _load_world_political_map_texture() -> Texture2D:
	var wmap_path := "res://data/theaters/world_political_map.png"
	if ResourceLoader.exists(wmap_path):
		return load(wmap_path)
	if not OS.has_feature("android"):
		var wmap_global := ProjectSettings.globalize_path(wmap_path)
		var w_img := Image.new()
		if FileAccess.file_exists(wmap_global) and w_img.load(wmap_global) == OK:
			return ImageTexture.create_from_image(w_img)
	return null


func _setup_controllers() -> void:
	if visual_sync != null:
		return
	visual_sync = VisualSyncScript.new()
	visual_sync.name = "VisualSyncController"
	visual_sync.war_table = self
	add_child(visual_sync)

	strike_preview = StrikePreviewScript.new()
	strike_preview.name = "StrikePreviewRenderer"
	strike_preview.war_table = self
	add_child(strike_preview)


func _rebuild_strategic_site_markers_and_domes() -> void:
	for c in _threat_domes_root.get_children():
		c.queue_free()
	for c in _site_labels_root.get_children():
		c.queue_free()

	if sim_server == null or sim_server.sim_db_ref == null:
		return

	# Update terrain shader heightmap texture & real-world GIS Lat/Lon bounding box to match the active theater
	var t_slug: String = String(sim_server.world_state.active_theater_slug)
	var geo_cfg := _get_theater_geopolitical_config(t_slug)
	if terrain_material != null:
		var hmap_path: String = String(sim_server.world_state.active_heightmap_path)
		if not hmap_path.is_empty():
			if ResourceLoader.exists(hmap_path):
				terrain_material.set_shader_parameter("heightmap_tex", load(hmap_path))
			elif not OS.has_feature("android"):
				var hmap_global := ProjectSettings.globalize_path(hmap_path)
				var h_img := Image.new()
				if FileAccess.file_exists(hmap_global) and h_img.load(hmap_global) == OK:
					terrain_material.set_shader_parameter("heightmap_tex", ImageTexture.create_from_image(h_img))
		terrain_material.set_shader_parameter("theater_latlon_box", geo_cfg["latlon_box"])
		terrain_material.set_shader_parameter("sovereign_border_segment", geo_cfg["border_uv"])

	# Spawn 3D Holographic Sovereign Country Banners & International Demarcation Line Label on the War Table
	for c_banner in geo_cfg["country_banners"]:
		var bx := float(c_banner[1])
		var bz := float(c_banner[2])
		var b_elev: float = maxf(0.0, sim_server.world_state.get_terrain_elevation_m(bx, bz))
		var b_lpos := theater_km_to_table_local(Vector3(bx, b_elev, bz))
		var b_lbl := Label3D.new()
		var raw_b_txt := String(c_banner[0])
		b_lbl.name = "SovereignBanner_" + raw_b_txt.substr(0, 12).strip_edges()
		b_lbl.text = raw_b_txt
		b_lbl.font_size = mini(int(c_banner[4]), 16)
		b_lbl.pixel_size = 0.00050
		b_lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		b_lbl.modulate = Color(c_banner[3].r, c_banner[3].g, c_banner[3].b, 0.82)
		b_lbl.position = b_lpos + Vector3(0.0, 0.072, 0.0)
		b_lbl.set_meta("site_km", Vector3(bx, b_elev, bz))
		b_lbl.set_meta("y_offset_m", 0.072)
		b_lbl.set_meta("is_continental_banner", raw_b_txt.begins_with("[CONTINENTAL:"))
		_site_labels_root.add_child(b_lbl)

	# Spawn 3D Golden C4ISR Metropolitan City Labels across the 500x500 km Theater
	var real_cities: Array[Dictionary] = CivilianDensitySystemScript.get_theater_real_cities(t_slug)
	for rc in real_cities:
		var rcx := float(rc.get("x_km", 0.0))
		var rcz := float(rc.get("z_km", 0.0))
		var rc_elev: float = maxf(0.0, sim_server.world_state.get_terrain_elevation_m(rcx, rcz))
		var rc_lpos := theater_km_to_table_local(Vector3(rcx, rc_elev, rcz))
		var rc_lbl := Label3D.new()
		rc_lbl.name = "RealCityLabel_" + String(rc.get("name", "CITY")).substr(0, 10).strip_edges()
		rc_lbl.text = "* " + String(rc.get("name", "CITY"))
		rc_lbl.font_size = 14
		rc_lbl.pixel_size = 0.00046
		rc_lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		rc_lbl.modulate = Color(1.0, 0.86, 0.36, 0.78)
		rc_lbl.position = rc_lpos + Vector3(0.0, 0.030, 0.0)
		rc_lbl.set_meta("site_km", Vector3(rcx, rc_elev, rcz))
		rc_lbl.set_meta("y_offset_m", 0.030)
		rc_lbl.set_meta("is_city_label", true)
		_site_labels_root.add_child(rc_lbl)

	var dome_shader: Shader = load("res://src/presentation/war_table/shaders/fresnel_dome.gdshader")
	var sites: Array = sim_server.world_state.active_sites
	if sites.is_empty():
		sites = sim_server.sim_db_ref.theater_sites

	for st in sites:
		var sx := float(st.get("x_km", 0.0))
		var sz := float(st.get("z_km", 0.0))
		var sname := String(st.get("site_name", "Site"))
		var fac_str := String(st.get("faction_owner", "BLUE"))
		var elev_m: float = sim_server.world_state.get_terrain_elevation_m(sx, sz)
		var local_pos := theater_km_to_table_local(Vector3(sx, maxf(0.0, elev_m), sz))

		# Strategic site label
		var lbl := Label3D.new()
		lbl.text = "[ %s ]" % sname.to_upper()
		lbl.font_size = 16
		lbl.pixel_size = 0.00052
		lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lbl.modulate = TacticalTheme.COL_NATO_BLUE if fac_str == "BLUE" else TacticalTheme.COL_OPFOR_RED
		lbl.position = local_pos + Vector3(0.0, 0.044, 0.0)
		lbl.set_meta("site_km", Vector3(sx, maxf(0.0, elev_m), sz))
		lbl.set_meta("y_offset_m", 0.044)
		_site_labels_root.add_child(lbl)

		# Fresnel Radar / SAM Dome over major airbases & SAM hubs
		var dome_mi := MeshInstance3D.new()
		var sph := SphereMesh.new()
		var dome_radius_m := 0.16 if fac_str == "RED" else 0.13
		sph.radius = dome_radius_m
		sph.height = dome_radius_m
		sph.is_hemisphere = true

		var dmat := ShaderMaterial.new()
		dmat.shader = dome_shader
		var dcol := Color(0.0, 0.85, 1.0, 0.35) if fac_str == "BLUE" else Color(1.0, 0.165, 0.33, 0.42)
		dmat.set_shader_parameter("dome_color", dcol)
		sph.material = dmat
		dome_mi.mesh = sph
		dome_mi.position = local_pos
		dome_mi.set_meta("site_km", Vector3(sx, maxf(0.0, elev_m), sz))
		dome_mi.set_meta("base_radius_m", dome_radius_m)
		_threat_domes_root.add_child(dome_mi)


func _get_theater_geopolitical_config(t_slug: String) -> Dictionary:
	var col_blue := Color(0.25, 0.92, 1.0, 0.94)
	var col_red := Color(1.0, 0.32, 0.45, 0.94)
	var col_border := Color(1.0, 0.82, 0.25, 0.95)
	if t_slug.find("hormuz") != -1:
		return {
			"latlon_box": Vector4(47.0, 17.5, 65.0, 34.5),
			"border_uv": Vector4(0.05, 0.52, 0.95, 0.44),
			"country_banners": [
				["<< ISLAMIC REPUBLIC OF IRAN (IRGC / ARTESH — 25,000 UNITS) >>", -15.0, -165.0, col_red, 24],
				["<< US 5TH FLEET (USS LINCOLN CVN-72) & COALITION (25,000 UNITS) >>", 10.0, 165.0, col_blue, 24],
				["--- STRAIT OF HORMUZ MARITIME DEMARCATION (2,000x2,000 KM) ---", 0.0, -10.0, col_border, 19],
				["[CONTINENTAL: IRANIAN PLATEAU / TEHRAN-SHIRAZ]", 40.0, -365.0, col_red, 22],
				["[CONTINENTAL: SAUDI ARABIA & U.A.E. (GCC)]", -320.0, 320.0, col_blue, 22],
				["[ARABIAN SEA & GULF OF OMAN SECTOR]", 330.0, 320.0, col_border, 20],
			]
		}
	elif t_slug.find("korea") != -1:
		return {
			"latlon_box": Vector4(118.0, 30.0, 136.5, 46.0),
			"border_uv": Vector4(0.10, 0.52, 0.90, 0.45),
			"country_banners": [
				["<< D.P.R. KOREA (KPA II/IV CORPS & 105TH TANK DIV — 58,000 UNITS) >>", -20.0, -165.0, col_red, 24],
				["<< R.O.K. VII CORPS & US 7TH AF (ROKS JEONGJO — 52,000 UNITS) >>", 15.0, 165.0, col_blue, 24],
				["--- 38TH PARALLEL MILITARY DEMARCATION LINE (2,000x2,000 KM) ---", 0.0, -5.0, col_border, 19],
				["[CONTINENTAL: P.R. CHINA (MANCHURIA / NORTHERN THEATER)]", -340.0, -340.0, col_red, 22],
				["[CONTINENTAL: JAPAN (KYUSHU / HONSHU SELF-DEFENSE)]", 350.0, 310.0, col_blue, 22],
				["[YELLOW SEA & EAST SEA MARITIME SECTOR]", -340.0, 220.0, col_border, 20],
			]
		}
	elif t_slug.find("baltic") != -1 or t_slug.find("suwalki") != -1:
		return {
			"latlon_box": Vector4(12.0, 46.5, 32.5, 62.0),
			"border_uv": Vector4(0.32, 0.15, 0.68, 0.85),
			"country_banners": [
				["<< NATO MNC-NE (POL 18TH DIV, GER 45TH BDE, FS DE GAULLE — 82k UNITS) >>", 85.0, 135.0, col_blue, 24],
				["<< RUS 11TH CORPS KALININGRAD & 1ST GUARDS TANK ARMY (78k UNITS) >>", -135.0, -110.0, col_red, 24],
				["--- SUWALKI GAP NATO SOVEREIGN FRONTIER (2,000x2,000 KM) ---", -15.0, 10.0, col_border, 19],
				["[CONTINENTAL: POLAND & CENTRAL EUROPE (NATO)]", -240.0, 360.0, col_blue, 22],
				["[CONTINENTAL: BALTIC STATES & FINLAND (NATO)]", 160.0, -360.0, col_blue, 22],
				["[CONTINENTAL: BELARUS & RUSSIAN WESTERN MD]", 350.0, 180.0, col_red, 22],
			]
		}
	elif t_slug.find("himalaya") != -1 or t_slug.find("lac") != -1:
		return {
			"latlon_box": Vector4(69.0, 25.0, 88.0, 42.0),
			"border_uv": Vector4(0.22, 0.08, 0.78, 0.92),
			"country_banners": [
				["<< INDIA XIV 'FIRE & FURY' CORPS & INS VIKRANT (75,000 UNITS) >>", -135.0, 110.0, col_blue, 24],
				["<< PLA WESTERN THEATER (76TH/77TH GA) & PAK X CORPS (75,000 UNITS) >>", 135.0, -110.0, col_red, 24],
				["--- HIMALAYAN LINE OF ACTUAL CONTROL (LAC 2,000x2,000 KM) ---", 0.0, 0.0, col_border, 19],
				["[CONTINENTAL: REPUBLIC OF INDIA (NEW DELHI / AMBALA)]", -240.0, 365.0, col_blue, 22],
				["[CONTINENTAL: P.R. CHINA (TIBETAN PLATEAU / HOTAN)]", 330.0, -340.0, col_red, 22],
				["[CONTINENTAL: PAKISTAN (ISLAMABAD / SKARDU)]", -360.0, -160.0, col_border, 20],
			]
		}
	elif t_slug.find("ukraine") != -1 or t_slug.find("donbas") != -1:
		return {
			"latlon_box": Vector4(24.0, 41.0, 44.0, 55.5),
			"border_uv": Vector4(0.54, 0.05, 0.42, 0.88),
			"country_banners": [
				["<< UKRAINE ZSU (47TH MAGURA, 3RD ASSAULT, 414TH MADYAR — 115k UNITS) >>", -125.0, -35.0, col_blue, 24],
				["<< RUSSIA VSRF (1ST GUARDS TANK, 8TH/58TH CAA, ADM. GORSHKOV — 125k UNITS) >>", 115.0, -25.0, col_red, 24],
				["--- DONBAS-ZAPORIZHZHIA-CRIMEA FRONTLINE (2,000x2,000 KM) ---", -5.0, 5.0, col_border, 19],
				["[CONTINENTAL: KYIV / LVIV & NATO POLAND-ROMANIA HUB]", -340.0, -240.0, col_blue, 22],
				["[CONTINENTAL: MOSCOW / VORONEZH / ENGELS-2 STRATEGIC BASE]", 340.0, -280.0, col_red, 22],
				["[BLACK SEA & SEA OF AZOV LITTORAL (ODESA - SEVASTOPOL)]", -80.0, 340.0, col_border, 20],
			]
		}
	elif t_slug.find("mexico") != -1 or t_slug.find("rio_grande") != -1:
		return {
			"latlon_box": Vector4(-108.0, 18.0, -90.0, 34.5),
			"border_uv": Vector4(0.05, 0.38, 0.92, 0.56),
			"country_banners": [
				["<< USA NORTHCOM (III CORPS 1ST CAV, 388TH WING, USS FORD — 36k UNITS) >>", -20.0, -145.0, col_blue, 24],
				["<< MEXICO SEDENA (1/A BDE BLINDADA, FAM ESC. 401, POLA-101 — 34k UNITS) >>", -30.0, 135.0, col_red, 24],
				["--- US-MEXICO RIO GRANDE / SIERRA MADRE FRONTIER (2,000x2,000 KM) ---", -10.0, -5.0, col_border, 19],
				["[CONTINENTAL: TEXAS / FORT CAVAZOS / SAN ANTONIO CORRIDOR]", -220.0, -340.0, col_blue, 22],
				["[CONTINENTAL: MEXICO CITY (BAM-1 SANTA LUCIA) & CENTRAL MEXICO]", -180.0, 355.0, col_red, 22],
				["[GULF OF MEXICO MARITIME SECTOR (CORPUS CHRISTI - VERACRUZ)]", 335.0, 40.0, col_border, 20],
			]
		}
	# Default: Taiwan Strait (`strait_theater`)
	return {
		"latlon_box": Vector4(111.0, 16.0, 129.5, 32.5),
		"border_uv": Vector4(0.48, 0.04, 0.42, 0.96),
		"country_banners": [
			["<< P.R. CHINA PLA EASTERN THEATER (71/72/73 GA, CNS FUJIAN — 120k UNITS) >>", -155.0, -40.0, col_red, 24],
			["<< USA 7TH FLEET (USS FORD CVN-78) & R.O.C. TAIWAN (100k UNITS) >>", 135.0, 20.0, col_blue, 24],
			["--- TAIWAN STRAIT MEDIAN LINE (2,000x2,000 KM THEATER) ---", -20.0, 0.0, col_border, 19],
			["[CONTINENTAL: MAINLAND CHINA (SHANGHAI / GUANGDONG / HAINAN)]", -355.0, -180.0, col_red, 22],
			["[CONTINENTAL: JAPAN / OKINAWA (KADENA AB) & RYUKYU]", 345.0, -290.0, col_blue, 22],
			["[CONTINENTAL: PHILIPPINES / LUZON STRAIT]", 140.0, 365.0, col_blue, 22],
			["[SOUTH CHINA SEA MARITIME SECTOR]", -290.0, 345.0, col_border, 20],
		]
	}


func _process(delta: float) -> void:
	# Smooth exponential damping (Section 0.2 of IMPLEMENTATION_PLAN.md)
	var damp := 1.0 - exp(-12.0 * delta)
	zoom_scale = lerpf(zoom_scale, target_zoom_scale, damp)
	pan_offset_km = pan_offset_km.lerp(target_pan_offset_km, damp)
	if _planetary_globe_root != null and _planetary_globe_root.visible:
		_planetary_globe_root.rotation.y += delta * 0.14
	_apply_shader_zoom_and_pan()


func set_zoom_and_pan(new_zoom: float, new_pan_km: Vector2 = target_pan_offset_km, instant: bool = false) -> void:
	target_zoom_scale = clampf(new_zoom, 0.15, 25.0)
	target_pan_offset_km = Vector2(
		clampf(new_pan_km.x, -220.0, 220.0),
		clampf(new_pan_km.y, -220.0, 220.0)
	)
	if instant:
		zoom_scale = target_zoom_scale
		pan_offset_km = target_pan_offset_km
		_apply_shader_zoom_and_pan()
		if visual_sync != null:
			visual_sync.sync_visuals()


## Cycles between Planetary Orbital Globe (0.22x), Continental Curved Space Sector (0.55x),
## Theater Operational (1.2x), and Tactical Valley (5.5x).
func cycle_macro_space_zoom() -> void:
	if target_zoom_scale >= 3.0:
		set_zoom_and_pan(1.0, Vector2.ZERO)
	elif target_zoom_scale >= 0.90:
		set_zoom_and_pan(0.52, Vector2.ZERO) # 4,000 km Continental Curved Space Map
	elif target_zoom_scale >= 0.38:
		set_zoom_and_pan(0.22, Vector2.ZERO) # Whole-Planet Holographic Orbital Globe
	else:
		set_zoom_and_pan(5.0, Vector2.ZERO)


func get_active_zoom_tier_name() -> String:
	if zoom_scale < 0.42:
		return "TIER 4: PLANETARY ORBITAL GLOBE (40,000 KM // 1,000,000 GLOBAL UNITS)"
	elif zoom_scale < 0.95:
		return "TIER 3: CONTINENTAL CURVED SPACE SECTOR (8,000 KM)"
	elif zoom_scale < 2.2:
		return "TIER 2: THEATER MACRO (2,000 KM)"
	elif zoom_scale < 6.5:
		return "TIER 1: OPERATIONAL SECTOR (250 KM)"
	return "TIER 0: TACTICAL VALLEY MICRO (<15 KM)"


func is_planetary_globe_visible() -> bool:
	return _planetary_globe_root != null and _planetary_globe_root.visible


func set_graphic_style_mode(mode: int) -> String:
	graphic_style_mode = posmod(mode, GRAPHIC_STYLE_NAMES.size())
	if terrain_material != null:
		terrain_material.set_shader_parameter("graphic_style_mode", graphic_style_mode)
	return get_graphic_style_name()


func cycle_graphic_style_mode() -> String:
	return set_graphic_style_mode(graphic_style_mode + 1)


func get_graphic_style_name() -> String:
	if graphic_style_mode >= 0 and graphic_style_mode < GRAPHIC_STYLE_NAMES.size():
		return GRAPHIC_STYLE_NAMES[graphic_style_mode]
	return GRAPHIC_STYLE_NAMES[0]


func _apply_shader_zoom_and_pan() -> void:
	if terrain_material != null:
		terrain_material.set_shader_parameter("table_zoom", zoom_scale)
		terrain_material.set_shader_parameter("table_pan_uv", pan_offset_km / THEATER_SIZE_KM)
	if sim_server != null and sim_server.has_method("set_sim_focus"):
		var sel_id: int = visual_sync.selected_unit_id if visual_sync != null else -1
		sim_server.set_sim_focus(pan_offset_km, zoom_scale, sel_id)

	var globe_mode: bool = (zoom_scale < 0.42)
	if _planetary_globe_root != null:
		_planetary_globe_root.visible = globe_mode
	if terrain_mesh_instance != null:
		terrain_mesh_instance.visible = not globe_mode
	if _site_labels_root != null:
		_site_labels_root.visible = not globe_mode
	if _threat_domes_root != null:
		_threat_domes_root.visible = not globe_mode

	# Keep strategic site labels, sovereign country banners & Fresnel domes aligned with table zoom/pan
	if not globe_mode and _site_labels_root != null:
		for lbl in _site_labels_root.get_children():
			if lbl.has_meta("site_km"):
				var skm: Vector3 = lbl.get_meta("site_km")
				var y_off: float = float(lbl.get_meta("y_offset_m")) if lbl.has_meta("y_offset_m") else 0.044
				var lpos := theater_km_to_table_local(skm)
				lbl.position = lpos + Vector3(0.0, y_off, 0.0)
				var in_bounds := absf(lpos.x) <= 0.88 and absf(lpos.z) <= 0.88
				var is_cont: bool = bool(lbl.get_meta("is_continental_banner")) if lbl.has_meta("is_continental_banner") else false
				var is_city: bool = bool(lbl.get_meta("is_city_label")) if lbl.has_meta("is_city_label") else false
				if is_cont:
					lbl.visible = in_bounds and (zoom_scale < 0.85)
				elif is_city:
					lbl.visible = in_bounds and (zoom_scale >= 1.15)
				else:
					lbl.visible = in_bounds

	if not globe_mode and _threat_domes_root != null:
		for dome in _threat_domes_root.get_children():
			if dome.has_meta("site_km"):
				var skm: Vector3 = dome.get_meta("site_km")
				var lpos := theater_km_to_table_local(skm)
				dome.position = lpos
				dome.scale = Vector3.ONE * clampf(zoom_scale, 0.45, 3.5)
				dome.visible = absf(lpos.x) <= 0.88 and absf(lpos.z) <= 0.88


## Semantic Zoom Echelon Selector:
## - Macro View (`zoom_scale < 2.2`): Brigades / Wings (Echelon 2)
## - Operational View (`2.2 <= zoom_scale < 6.5`): Battalions / Squadrons (Echelon 1)
## - Tactical Valley View (`zoom_scale >= 6.5`): Individual Flights, Platoons & Robot Dog Packs (Echelon 0)
func get_active_semantic_echelon() -> int:
	if visual_sync != null and visual_sync.force_all_tokens:
		return WorldState.ECHELON_COMPANY
	if zoom_scale < 2.2:
		return WorldState.ECHELON_BRIGADE
	elif zoom_scale < 6.5:
		return WorldState.ECHELON_BATTALION
	return WorldState.ECHELON_COMPANY


func theater_km_to_table_local(pos_km: Vector3) -> Vector3:
	var rel_x_km := (pos_km.x - pan_offset_km.x) * zoom_scale
	var rel_z_km := (pos_km.z - pan_offset_km.y) * zoom_scale
	var local_x := (rel_x_km / THEATER_SIZE_KM) * TABLE_SIZE_M
	var local_z := (rel_z_km / THEATER_SIZE_KM) * TABLE_SIZE_M

	var terrain_elev_m := 0.0
	if sim_server != null:
		terrain_elev_m = maxf(0.0, sim_server.world_state.get_terrain_elevation_m(pos_km.x, pos_km.z))
	var terrain_disp_y := (terrain_elev_m / 3800.0) * 0.78 * 0.11 * minf(zoom_scale, 4.0)
	var curve_factor := clampf((1.0 - zoom_scale) / 0.65, 0.0, 1.0)
	var r2 := local_x * local_x + local_z * local_z
	var planet_dome_y := maxf(0.0, 0.145 * (1.0 - r2 / 1.65)) * curve_factor
	var agl_m := maxf(0.0, pos_km.y - terrain_elev_m)
	var eff_alt_m := agl_m
	if agl_m > 16000.0:
		# Smooth logarithmic compression for mesospheric ballistic missiles (35-85 km) & LEO/MEO satellites/rods (525-20,200 km)
		eff_alt_m = 16000.0 + log(1.0 + (agl_m - 16000.0) / 10000.0) * 1850.0
	var air_offset_y := eff_alt_m * ALTITUDE_M_TO_TABLE_M * minf(zoom_scale, 2.5)
	return Vector3(local_x, terrain_disp_y + planet_dome_y + air_offset_y, local_z)


func table_local_to_theater_km(local_pos: Vector3) -> Vector3:
	var rel_x_km := (local_pos.x / TABLE_SIZE_M) * (THEATER_SIZE_KM / maxf(zoom_scale, 1.0))
	var rel_z_km := (local_pos.z / TABLE_SIZE_M) * (THEATER_SIZE_KM / maxf(zoom_scale, 1.0))
	var x_km := clampf(rel_x_km + pan_offset_km.x, -248.0, 248.0)
	var z_km := clampf(rel_z_km + pan_offset_km.y, -248.0, 248.0)
	var elev_m := 0.0
	if sim_server != null:
		elev_m = maxf(0.0, sim_server.world_state.get_terrain_elevation_m(x_km, z_km))
	return Vector3(x_km, elev_m, z_km)


func table_local_to_world(local_pos: Vector3) -> Vector3:
	return to_global(local_pos) if is_inside_tree() else (position + local_pos)


func world_to_table_local(world_pos: Vector3) -> Vector3:
	return to_local(world_pos) if is_inside_tree() else (world_pos - position)


func world_to_theater_km(world_pos: Vector3) -> Vector3:
	return table_local_to_theater_km(world_to_table_local(world_pos))


func pick_unit_at_theater_km(x_km: float, z_km: float, max_pick_km: float = 25.0) -> int:
	if sim_server == null:
		return -1
	var state: WorldState = sim_server.world_state
	var active_ech := get_active_semantic_echelon()
	var best_uid := -1
	var best_d_sq := (max_pick_km / maxf(1.0, zoom_scale * 0.45)) ** 2

	# First pass: check active semantic echelon OR any airborne Company flight (since 3D jets are always visible)
	for uid in range(state.unit_count):
		if state.unit_active[uid] == 0:
			continue
		var ech := state.unit_echelon[uid]
		var is_air_leaf := (ech == WorldState.ECHELON_COMPANY and state.unit_pos[uid].y > 200.0)
		if not (visual_sync != null and visual_sync.force_all_tokens) and ech != active_ech and not is_air_leaf:
			continue
		var upos := state.unit_pos[uid]
		var d_sq := Vector2(upos.x - x_km, upos.z - z_km).distance_squared_to(Vector2.ZERO)
		if d_sq < best_d_sq:
			best_d_sq = d_sq
			best_uid = uid

	# Fallback pass: if nothing matched, check all active leaf units
	if best_uid == -1:
		best_d_sq = (max_pick_km / maxf(1.0, zoom_scale * 0.45)) ** 2
		for uid in range(state.unit_count):
			if state.unit_active[uid] == 0 or state.unit_echelon[uid] != WorldState.ECHELON_COMPANY:
				continue
			var upos := state.unit_pos[uid]
			var d_sq := Vector2(upos.x - x_km, upos.z - z_km).distance_squared_to(Vector2.ZERO)
			if d_sq < best_d_sq:
				best_d_sq = d_sq
				best_uid = uid
	return best_uid


## True 3D Tacview Ray Picker: selects airborne 3D jets floating high above the table OR ground/sea tokens.
func pick_unit_by_ray(ray_origin_world: Vector3, ray_dir_world: Vector3) -> int:
	if sim_server == null:
		return -1
	var state: WorldState = sim_server.world_state
	var active_ech := get_active_semantic_echelon()
	var dir_n := ray_dir_world.normalized()
	var best_uid := -1
	var best_perp_dist := 0.055 # 5.5 cm 3D selection radius in world space

	for uid in range(state.unit_count):
		if state.unit_active[uid] == 0:
			continue
		var ech := state.unit_echelon[uid]
		var is_air_leaf := (ech == WorldState.ECHELON_COMPANY and state.unit_pos[uid].y > 200.0)
		if not (visual_sync != null and visual_sync.force_all_tokens) and ech != active_ech and not is_air_leaf:
			continue
		var local_pos := theater_km_to_table_local(state.unit_pos[uid])
		if absf(local_pos.x) > 0.92 or absf(local_pos.z) > 0.92:
			continue
		var world_pos := table_local_to_world(local_pos + Vector3(0.0, 0.01, 0.0))
		var to_pt := world_pos - ray_origin_world
		var proj := to_pt.dot(dir_n)
		if proj <= 0.05:
			continue
		var closest_on_ray := ray_origin_world + dir_n * proj
		var perp_dist := world_pos.distance_to(closest_on_ray)
		# Prioritize friendly units slightly when overlapping
		if state.unit_faction[uid] == WorldState.FACTION_BLUE:
			perp_dist *= 0.85
		if perp_dist < best_perp_dist:
			best_perp_dist = perp_dist
			best_uid = uid

	return best_uid


## Raycasts against the 7 Global Flashpoint Beacons on the 3D Planetary Globe (`zoom_scale < 0.42`).
func pick_flashpoint_on_globe_by_ray(ray_origin_world: Vector3, ray_dir_world: Vector3) -> String:
	if _planetary_globe_root == null or not _planetary_globe_root.visible:
		return ""
	var dir_n := ray_dir_world.normalized()
	var best_slug := ""
	var best_dist := 0.085
	for child in _planetary_globe_root.get_children():
		if child is Node3D and child.has_meta("scenario_slug"):
			var wpos: Vector3 = child.global_position if child.is_inside_tree() else (position + _planetary_globe_root.position + _planetary_globe_root.transform.basis * child.position)
			var to_pt := wpos - ray_origin_world
			var proj := to_pt.dot(dir_n)
			if proj <= 0.05:
				continue
			var closest := ray_origin_world + dir_n * proj
			var perp := wpos.distance_to(closest)
			if perp < best_dist:
				best_dist = perp
				best_slug = String(child.get_meta("scenario_slug"))
	return best_slug


## Selects all friendly leaf units inside a 3D world-space sphere on the War Table (used by VR 3D Volume Selection).
func pick_units_in_sphere_world(center_world: Vector3, radius_world_m: float) -> Array[int]:
	var result: Array[int] = []
	if sim_server == null:
		return result
	var state: WorldState = sim_server.world_state
	var rad_sq := radius_world_m * radius_world_m
	for uid in range(state.unit_count):
		if state.unit_active[uid] == 0 or state.unit_faction[uid] != WorldState.FACTION_BLUE or state.unit_echelon[uid] != WorldState.ECHELON_COMPANY:
			continue
		var local_pos := theater_km_to_table_local(state.unit_pos[uid])
		if absf(local_pos.x) > 0.92 or absf(local_pos.z) > 0.92:
			continue
		var world_pos := table_local_to_world(local_pos + Vector3(0.0, 0.01, 0.0))
		if world_pos.distance_squared_to(center_world) <= rad_sq:
			result.append(uid)
	return result
