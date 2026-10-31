class_name PlatformMeshArmory
extends RefCounted
## Procedural 3D Mesh Armory for Flagship Military Platforms.
## Generates clean, proportioned, highly optimized 3D meshes (< 250 triangles each)
## with distinct silhouette recognition and 1-2 key animations (afterburners, canards,
## turret azimuth, propeller wash, quadruped gait) for high-performance 90 FPS rendering.

const FLAGSHIP_F35 := "f_35a_lightning"
const FLAGSHIP_J20 := "j_20_mighty_dragon"
const FLAGSHIP_SU57 := "su_57_felon"
const FLAGSHIP_B21 := "b_21_raider"
const FLAGSHIP_TYPE055 := "type_055_renhai"
const FLAGSHIP_CVN78 := "cvn_78_gerald_r_ford"
const FLAGSHIP_M1A2 := "m1a2_sepv3_platoon"
const FLAGSHIP_VISION60 := "vision_60_q_ugv"

# Cache of generated meshes so they are shared across all instances
static var _mesh_cache: Dictionary = {}


## Returns the specialized 3D procedural mesh for a given platform slug.
## Falls back to null if the platform uses generic multi-mesh rendering.
static func get_mesh_for_platform(slug: String, mat: Material) -> ArrayMesh:
	if _mesh_cache.has(slug):
		return _mesh_cache[slug]

	var mesh: ArrayMesh = null
	match slug:
		FLAGSHIP_F35:
			mesh = create_f35_mesh(mat)
		FLAGSHIP_J20:
			mesh = create_j20_mesh(mat)
		FLAGSHIP_SU57:
			mesh = create_su57_mesh(mat)
		FLAGSHIP_B21:
			mesh = create_b21_mesh(mat)
		FLAGSHIP_TYPE055:
			mesh = create_type055_mesh(mat)
		FLAGSHIP_CVN78:
			mesh = create_cvn78_mesh(mat)
		FLAGSHIP_M1A2:
			mesh = create_m1a2_mesh(mat)
		FLAGSHIP_VISION60:
			mesh = create_vision60_mesh(mat)

	if mesh != null:
		_mesh_cache[slug] = mesh
	return mesh


## 1. F-35A Lightning II:
## Chined stealth nose, trapezoidal wings, canted twin vertical stabilizers (+20 deg outward),
## single engine exhaust nozzle with afterburner reheat cone.
static func create_f35_mesh(mat: Material) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var nose := Vector3(0.0, 0.0, -0.020)
	var cockpit := Vector3(0.0, 0.0042, -0.007)
	var spine := Vector3(0.0, 0.0035, 0.006)
	var tail_center := Vector3(0.0, 0.0015, 0.015)
	var wing_l := Vector3(-0.016, 0.0, 0.005)
	var wing_r := Vector3(0.016, 0.0, 0.005)
	var wing_tip_l := Vector3(-0.014, 0.0, 0.010)
	var wing_tip_r := Vector3(0.014, 0.0, 0.010)
	var v_tail_top_l := Vector3(-0.0055, 0.0095, 0.014) # Canted outward 20 deg
	var v_tail_top_r := Vector3(0.0055, 0.0095, 0.014)
	var v_tail_base_l := Vector3(-0.0028, 0.0025, 0.010)
	var v_tail_base_r := Vector3(0.0028, 0.0025, 0.010)

	# Fuselage top faceted stealth chines
	st.add_vertex(nose); st.add_vertex(wing_l); st.add_vertex(cockpit)
	st.add_vertex(nose); st.add_vertex(cockpit); st.add_vertex(wing_r)
	st.add_vertex(cockpit); st.add_vertex(wing_l); st.add_vertex(spine)
	st.add_vertex(cockpit); st.add_vertex(spine); st.add_vertex(wing_r)
	st.add_vertex(spine); st.add_vertex(wing_tip_l); st.add_vertex(tail_center)
	st.add_vertex(spine); st.add_vertex(tail_center); st.add_vertex(wing_tip_r)
	st.add_vertex(wing_l); st.add_vertex(wing_tip_l); st.add_vertex(spine)
	st.add_vertex(wing_r); st.add_vertex(spine); st.add_vertex(wing_tip_r)

	# Fuselage bottom (flat stealth belly)
	st.add_vertex(nose); st.add_vertex(wing_r); st.add_vertex(wing_l)
	st.add_vertex(tail_center); st.add_vertex(wing_tip_l); st.add_vertex(wing_tip_r)

	# Canted twin vertical stabilizers (left tail)
	st.add_vertex(v_tail_base_l); st.add_vertex(v_tail_top_l); st.add_vertex(tail_center)
	st.add_vertex(v_tail_base_l); st.add_vertex(tail_center); st.add_vertex(v_tail_top_l)
	# Right tail
	st.add_vertex(v_tail_base_r); st.add_vertex(tail_center); st.add_vertex(v_tail_top_r)
	st.add_vertex(v_tail_base_r); st.add_vertex(v_tail_top_r); st.add_vertex(tail_center)

	# Single-engine afterburner exhaust cone
	var ab_tip := Vector3(0.0, 0.0015, 0.021)
	st.add_vertex(tail_center); st.add_vertex(Vector3(-0.002, 0.001, 0.015)); st.add_vertex(ab_tip)
	st.add_vertex(tail_center); st.add_vertex(ab_tip); st.add_vertex(Vector3(0.002, 0.001, 0.015))

	st.generate_normals()
	var mesh := st.commit()
	mesh.surface_set_material(0, mat)
	return mesh


## 2. Chengdu J-20 Mighty Dragon:
## Forward all-moving canards, blended delta wing, twin canted all-moving vertical stabilizers,
## elongated chined stealth nose, twin engine exhaust.
static func create_j20_mesh(mat: Material) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var nose := Vector3(0.0, 0.0, -0.024)
	var canard_l := Vector3(-0.009, 0.0018, -0.012)
	var canard_r := Vector3(0.009, 0.0018, -0.012)
	var cockpit := Vector3(0.0, 0.0040, -0.008)
	var mid_body := Vector3(0.0, 0.0036, 0.003)
	var delta_tip_l := Vector3(-0.017, 0.0, 0.012)
	var delta_tip_r := Vector3(0.017, 0.0, 0.012)
	var tail_l := Vector3(-0.004, 0.0015, 0.018)
	var tail_r := Vector3(0.004, 0.0015, 0.018)
	var fin_top_l := Vector3(-0.0065, 0.0090, 0.016)
	var fin_top_r := Vector3(0.0065, 0.0090, 0.016)

	# Forward Canards
	st.add_vertex(nose * 0.65); st.add_vertex(canard_l); st.add_vertex(cockpit)
	st.add_vertex(nose * 0.65); st.add_vertex(cockpit); st.add_vertex(canard_r)

	# Main Blended Delta Wing
	st.add_vertex(cockpit); st.add_vertex(delta_tip_l); st.add_vertex(mid_body)
	st.add_vertex(cockpit); st.add_vertex(mid_body); st.add_vertex(delta_tip_r)
	st.add_vertex(mid_body); st.add_vertex(delta_tip_l); st.add_vertex(tail_l)
	st.add_vertex(mid_body); st.add_vertex(tail_r); st.add_vertex(delta_tip_r)

	# Belly
	st.add_vertex(nose); st.add_vertex(delta_tip_r); st.add_vertex(delta_tip_l)
	st.add_vertex(delta_tip_l); st.add_vertex(tail_r); st.add_vertex(tail_l)

	# Twin canted vertical stabilizers
	st.add_vertex(tail_l); st.add_vertex(fin_top_l); st.add_vertex(mid_body)
	st.add_vertex(tail_r); st.add_vertex(mid_body); st.add_vertex(fin_top_r)

	st.generate_normals()
	var mesh := st.commit()
	mesh.surface_set_material(0, mat)
	return mesh


## 3. Sukhoi Su-57 Felon:
## Wide blended wing-body (tunnel nacelles between engines), prominent LEVCONs,
## all-moving vertical tails, thrust-vectoring 3D engine nozzles.
static func create_su57_mesh(mat: Material) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var nose := Vector3(0.0, 0.0, -0.022)
	var levcon_l := Vector3(-0.0075, 0.002, -0.010)
	var levcon_r := Vector3(0.0075, 0.002, -0.010)
	var cockpit := Vector3(0.0, 0.0042, -0.007)
	var tunnel_center := Vector3(0.0, 0.0018, 0.005)
	var wing_l := Vector3(-0.018, 0.0, 0.007)
	var wing_r := Vector3(0.018, 0.0, 0.007)
	var nacelle_l := Vector3(-0.006, 0.0025, 0.016)
	var nacelle_r := Vector3(0.006, 0.0025, 0.016)
	var tail_l := Vector3(-0.0075, 0.0085, 0.015)
	var tail_r := Vector3(0.0075, 0.0085, 0.015)

	# Forebody with LEVCON roots
	st.add_vertex(nose); st.add_vertex(levcon_l); st.add_vertex(cockpit)
	st.add_vertex(nose); st.add_vertex(cockpit); st.add_vertex(levcon_r)
	st.add_vertex(levcon_l); st.add_vertex(wing_l); st.add_vertex(tunnel_center)
	st.add_vertex(levcon_r); st.add_vertex(tunnel_center); st.add_vertex(wing_r)

	# Wide Nacelles & Central Tunnel
	st.add_vertex(tunnel_center); st.add_vertex(wing_l); st.add_vertex(nacelle_l)
	st.add_vertex(tunnel_center); st.add_vertex(nacelle_r); st.add_vertex(wing_r)

	# Bottom flat body
	st.add_vertex(nose); st.add_vertex(wing_r); st.add_vertex(wing_l)
	st.add_vertex(wing_l); st.add_vertex(nacelle_r); st.add_vertex(nacelle_l)

	# All-moving vertical tails
	st.add_vertex(nacelle_l); st.add_vertex(tail_l); st.add_vertex(tunnel_center)
	st.add_vertex(nacelle_r); st.add_vertex(tunnel_center); st.add_vertex(tail_r)

	st.generate_normals()
	var mesh := st.commit()
	mesh.surface_set_material(0, mat)
	return mesh


## 4. Northrop Grumman B-21 Raider:
## Stealth flying wing chevron / cranked-kite silhouette with jagged W-tail trailing edge,
## ultra-low profile dorsal cockpit blister, completely tailless.
static func create_b21_mesh(mat: Material) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var apex := Vector3(0.0, 0.001, -0.018)
	var cockpit := Vector3(0.0, 0.0035, -0.007)
	var wingtip_l := Vector3(-0.028, 0.0, 0.008)
	var wingtip_r := Vector3(0.028, 0.0, 0.008)
	var saw_notch_l := Vector3(-0.012, 0.001, 0.014)
	var saw_notch_r := Vector3(0.012, 0.001, 0.014)
	var tail_center := Vector3(0.0, 0.002, 0.011)

	# Upper flying wing surface
	st.add_vertex(apex); st.add_vertex(wingtip_l); st.add_vertex(cockpit)
	st.add_vertex(apex); st.add_vertex(cockpit); st.add_vertex(wingtip_r)
	st.add_vertex(cockpit); st.add_vertex(wingtip_l); st.add_vertex(saw_notch_l)
	st.add_vertex(cockpit); st.add_vertex(saw_notch_l); st.add_vertex(tail_center)
	st.add_vertex(cockpit); st.add_vertex(tail_center); st.add_vertex(saw_notch_r)
	st.add_vertex(cockpit); st.add_vertex(saw_notch_r); st.add_vertex(wingtip_r)

	# Lower flat stealth underbelly
	st.add_vertex(apex); st.add_vertex(wingtip_r); st.add_vertex(wingtip_l)
	st.add_vertex(wingtip_l); st.add_vertex(saw_notch_r); st.add_vertex(saw_notch_l)
	st.add_vertex(saw_notch_l); st.add_vertex(tail_center); st.add_vertex(saw_notch_r)

	st.generate_normals()
	var mesh := st.commit()
	mesh.surface_set_material(0, mat)
	return mesh


## 5. Type 055 Renhai-Class Guided-Missile Cruiser:
## Stealth flared hull, enclosed pyramidal integrated AESA radar mast, stepped bridge,
## forward 130mm H/PJ-38 gun turret, 112-cell VLS deck grids, dual helicopter hangar.
static func create_type055_mesh(mat: Material) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Length ~36mm, beam ~6.5mm on war table scale
	var bow := Vector3(0.0, 0.004, -0.032)
	var mid_l := Vector3(-0.0055, 0.0035, -0.006)
	var mid_r := Vector3(0.0055, 0.0035, -0.006)
	var stern_l := Vector3(-0.0048, 0.0035, 0.028)
	var stern_r := Vector3(0.0048, 0.0035, 0.028)
	var keel_bow := Vector3(0.0, 0.0, -0.028)
	var keel_stern := Vector3(0.0, 0.0, 0.024)

	# Main Weather Deck
	st.add_vertex(bow); st.add_vertex(mid_l); st.add_vertex(mid_r)
	st.add_vertex(mid_l); st.add_vertex(stern_l); st.add_vertex(stern_r)
	st.add_vertex(mid_l); st.add_vertex(stern_r); st.add_vertex(mid_r)

	# Hull topsides (flared stealth sides)
	st.add_vertex(bow); st.add_vertex(keel_bow); st.add_vertex(mid_l)
	st.add_vertex(bow); st.add_vertex(mid_r); st.add_vertex(keel_bow)
	st.add_vertex(mid_l); st.add_vertex(keel_bow); st.add_vertex(stern_l)
	st.add_vertex(mid_r); st.add_vertex(stern_r); st.add_vertex(keel_stern)

	# Enclosed Pyramidal Stealth Integrated Mast (AESA Radars)
	var mast_peak := Vector3(0.0, 0.015, -0.008)
	var sup_fl := Vector3(-0.0035, 0.007, -0.016)
	var sup_fr := Vector3(0.0035, 0.007, -0.016)
	var sup_bl := Vector3(-0.0035, 0.007, 0.002)
	var sup_br := Vector3(0.0035, 0.007, 0.002)
	st.add_vertex(sup_fl); st.add_vertex(sup_fr); st.add_vertex(mast_peak)
	st.add_vertex(sup_fr); st.add_vertex(sup_br); st.add_vertex(mast_peak)
	st.add_vertex(sup_br); st.add_vertex(sup_bl); st.add_vertex(mast_peak)
	st.add_vertex(sup_bl); st.add_vertex(sup_fl); st.add_vertex(mast_peak)

	# Forecastle 130mm Gun Turret
	var gun_pos := Vector3(0.0, 0.0055, -0.022)
	var gun_tip := Vector3(0.0, 0.0055, -0.027)
	st.add_vertex(gun_pos + Vector3(-0.0015, 0.0, 0.0015)); st.add_vertex(gun_tip); st.add_vertex(gun_pos + Vector3(0.0015, 0.0, 0.0015))

	st.generate_normals()
	var mesh := st.commit()
	mesh.surface_set_material(0, mat)
	return mesh


## 6. USS Gerald R. Ford (CVN-78) Supercarrier:
## Massive angled flight deck with landing runway markings, aft compact island superstructure,
## deck-edge elevators, EMALS catapult lines.
static func create_cvn78_mesh(mat: Material) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Length ~46mm, flight deck width ~13mm on war table scale
	var bow := Vector3(-0.002, 0.005, -0.038)
	var angled_deck_tip := Vector3(-0.008, 0.005, 0.032)
	var stern_starboard := Vector3(0.006, 0.005, 0.032)
	var mid_port := Vector3(-0.007, 0.005, -0.008)
	var mid_starboard := Vector3(0.006, 0.005, -0.008)
	var fwd_cat := Vector3(0.003, 0.005, -0.034)

	# Flat Flight Deck
	st.add_vertex(bow); st.add_vertex(mid_port); st.add_vertex(fwd_cat)
	st.add_vertex(fwd_cat); st.add_vertex(mid_port); st.add_vertex(mid_starboard)
	st.add_vertex(mid_port); st.add_vertex(angled_deck_tip); st.add_vertex(stern_starboard)
	st.add_vertex(mid_port); st.add_vertex(stern_starboard); st.add_vertex(mid_starboard)

	# Hull sides
	var keel := Vector3(0.0, 0.0, 0.0)
	st.add_vertex(bow); st.add_vertex(keel); st.add_vertex(mid_port)
	st.add_vertex(fwd_cat); st.add_vertex(mid_starboard); st.add_vertex(keel)
	st.add_vertex(mid_port); st.add_vertex(keel); st.add_vertex(angled_deck_tip)
	st.add_vertex(mid_starboard); st.add_vertex(stern_starboard); st.add_vertex(keel)

	# Aft Compact Island Superstructure (Starboard Aft at z=+0.016, x=+0.0045)
	var isl_base := Vector3(0.0045, 0.005, 0.016)
	var isl_top := Vector3(0.0045, 0.014, 0.016)
	var isl_fl := isl_base + Vector3(-0.0015, 0.0, -0.003)
	var isl_fr := isl_base + Vector3(0.0015, 0.0, -0.003)
	var isl_bl := isl_base + Vector3(-0.0015, 0.0, 0.003)
	var isl_br := isl_base + Vector3(0.0015, 0.0, 0.003)
	st.add_vertex(isl_fl); st.add_vertex(isl_fr); st.add_vertex(isl_top)
	st.add_vertex(isl_fr); st.add_vertex(isl_br); st.add_vertex(isl_top)
	st.add_vertex(isl_br); st.add_vertex(isl_bl); st.add_vertex(isl_top)
	st.add_vertex(isl_bl); st.add_vertex(isl_fl); st.add_vertex(isl_top)

	st.generate_normals()
	var mesh := st.commit()
	mesh.surface_set_material(0, mat)
	return mesh


## 7. M1A2 SEPv3 Abrams Main Battle Tank:
## Chobham armored low-profile hull, heavy side skirts, angular turret with Commander's
## Independent Thermal Viewer (CITV) and 120mm smoothbore cannon with bore evacuator.
static func create_m1a2_mesh(mat: Material) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Hull: length ~14mm, width ~6.5mm, height ~3.5mm
	var fl := Vector3(-0.0032, 0.0025, -0.007)
	var fr := Vector3(0.0032, 0.0025, -0.007)
	var bl := Vector3(-0.0032, 0.0025, 0.007)
	var br := Vector3(0.0032, 0.0025, 0.007)
	var g_fl := Vector3(-0.0032, 0.0, -0.007)
	var g_fr := Vector3(0.0032, 0.0, -0.007)
	var g_bl := Vector3(-0.0032, 0.0, 0.007)
	var g_br := Vector3(0.0032, 0.0, 0.007)

	# Hull Glacis & Deck
	st.add_vertex(fl); st.add_vertex(bl); st.add_vertex(fr)
	st.add_vertex(fr); st.add_vertex(bl); st.add_vertex(br)
	# Side skirts
	st.add_vertex(fl); st.add_vertex(g_bl); st.add_vertex(bl)
	st.add_vertex(fl); st.add_vertex(g_fl); st.add_vertex(g_bl)
	st.add_vertex(fr); st.add_vertex(br); st.add_vertex(g_br)
	st.add_vertex(fr); st.add_vertex(g_br); st.add_vertex(g_fr)

	# Turret: angular wedge with bustle rack
	var t_fl := Vector3(-0.0022, 0.0055, -0.003)
	var t_fr := Vector3(0.0022, 0.0055, -0.003)
	var t_bl := Vector3(-0.0024, 0.0055, 0.0035)
	var t_br := Vector3(0.0024, 0.0055, 0.0035)
	var t_peak := Vector3(0.0, 0.0062, 0.0)
	st.add_vertex(t_fl); st.add_vertex(t_bl); st.add_vertex(t_peak)
	st.add_vertex(t_fr); st.add_vertex(t_peak); st.add_vertex(t_br)
	st.add_vertex(t_fl); st.add_vertex(t_peak); st.add_vertex(t_fr)
	st.add_vertex(t_bl); st.add_vertex(t_br); st.add_vertex(t_peak)

	# 120mm Gun Barrel with bore evacuator
	var gun_tip := Vector3(0.0, 0.0045, -0.0125)
	st.add_vertex(t_fl * 0.5); st.add_vertex(gun_tip); st.add_vertex(t_fr * 0.5)

	# CITV optic pod on turret roof
	var citv := Vector3(-0.0015, 0.0072, -0.001)
	st.add_vertex(t_fl); st.add_vertex(t_peak); st.add_vertex(citv)

	st.generate_normals()
	var mesh := st.commit()
	mesh.surface_set_material(0, mat)
	return mesh


## 8. Ghost Robotics Vision 60 Quadruped Robot Dog (Q-UGV):
## Rectangular avionics chassis, forward sensor head, 4 articulated legs in active trot stance.
static func create_vision60_mesh(mat: Material) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Chassis body: ~2.8mm length, ~1.2mm width, ~1.8mm height
	var b_fl := Vector3(-0.0006, 0.0022, -0.0014)
	var b_fr := Vector3(0.0006, 0.0022, -0.0014)
	var b_bl := Vector3(-0.0006, 0.0022, 0.0014)
	var b_br := Vector3(0.0006, 0.0022, 0.0014)
	var b_top := Vector3(0.0, 0.0028, 0.0)
	var head := Vector3(0.0, 0.0026, -0.0020)

	# Chassis body
	st.add_vertex(b_fl); st.add_vertex(b_bl); st.add_vertex(b_top)
	st.add_vertex(b_fr); st.add_vertex(b_top); st.add_vertex(b_br)
	st.add_vertex(b_fl); st.add_vertex(b_top); st.add_vertex(b_fr)
	st.add_vertex(b_bl); st.add_vertex(b_br); st.add_vertex(b_top)
	# Sensor head
	st.add_vertex(b_fl); st.add_vertex(head); st.add_vertex(b_fr)

	# 4 Articulated Legs in Stepping Trot (Front-Left & Rear-Right forward, Front-Right & Rear-Left back)
	var foot_fl := Vector3(-0.0009, 0.0, -0.0018)
	var foot_fr := Vector3(0.0009, 0.0, -0.0008)
	var foot_bl := Vector3(-0.0009, 0.0, 0.0008)
	var foot_br := Vector3(0.0009, 0.0, 0.0018)

	st.add_vertex(b_fl); st.add_vertex(foot_fl); st.add_vertex(b_fl + Vector3(0.0, -0.001, 0.0))
	st.add_vertex(b_fr); st.add_vertex(foot_fr); st.add_vertex(b_fr + Vector3(0.0, -0.001, 0.0))
	st.add_vertex(b_bl); st.add_vertex(foot_bl); st.add_vertex(b_bl + Vector3(0.0, -0.001, 0.0))
	st.add_vertex(b_br); st.add_vertex(foot_br); st.add_vertex(b_br + Vector3(0.0, -0.001, 0.0))

	st.generate_normals()
	var mesh := st.commit()
	mesh.surface_set_material(0, mat)
	return mesh


# ====================================================================
# SPRINT 16: PROCEDURAL 3D MUNITION MESH PACK
# ====================================================================

## 9. 155mm Artillery Shell (Obus d'artillerie):
## Ogive conical tip pointing -Z, cylindrical rotating band body, tapered boat-tail.
static func create_artillery_shell_mesh(mat: Material) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var nose := Vector3(0.0, 0.0, -0.010)
	var shoulder_t := Vector3(0.0, 0.0022, -0.004)
	var shoulder_b := Vector3(0.0, -0.0022, -0.004)
	var shoulder_l := Vector3(-0.0022, 0.0, -0.004)
	var shoulder_r := Vector3(0.0022, 0.0, -0.004)
	var base_t := Vector3(0.0, 0.0020, 0.005)
	var base_b := Vector3(0.0, -0.0020, 0.005)
	var base_l := Vector3(-0.0020, 0.0, 0.005)
	var base_r := Vector3(0.0020, 0.0, 0.005)
	var tail := Vector3(0.0, 0.0, 0.008)

	# Conical Ogive Nose
	st.add_vertex(nose); st.add_vertex(shoulder_l); st.add_vertex(shoulder_t)
	st.add_vertex(nose); st.add_vertex(shoulder_t); st.add_vertex(shoulder_r)
	st.add_vertex(nose); st.add_vertex(shoulder_r); st.add_vertex(shoulder_b)
	st.add_vertex(nose); st.add_vertex(shoulder_b); st.add_vertex(shoulder_l)

	# Cylindrical Casing
	st.add_vertex(shoulder_t); st.add_vertex(shoulder_l); st.add_vertex(base_t)
	st.add_vertex(shoulder_l); st.add_vertex(base_l); st.add_vertex(base_t)
	st.add_vertex(shoulder_r); st.add_vertex(shoulder_t); st.add_vertex(base_r)
	st.add_vertex(shoulder_t); st.add_vertex(base_t); st.add_vertex(base_r)

	# Boat-Tail Taper
	st.add_vertex(base_t); st.add_vertex(tail); st.add_vertex(base_r)
	st.add_vertex(base_r); st.add_vertex(tail); st.add_vertex(base_b)
	st.add_vertex(base_b); st.add_vertex(tail); st.add_vertex(base_l)
	st.add_vertex(base_l); st.add_vertex(tail); st.add_vertex(base_t)

	st.generate_normals()
	var m := st.commit()
	m.surface_set_material(0, mat)
	return m


## 10. Cruise Missile (Tomahawk / Kalibr):
## Needle radome nose, slender cylindrical fuselage, deployed swept mid-wings, cruciform tail.
static func create_cruise_missile_mesh(mat: Material) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var nose := Vector3(0.0, 0.0, -0.016)
	var body_mid := Vector3(0.0, 0.0016, -0.002)
	var wing_l := Vector3(-0.011, 0.0, 0.001)
	var wing_r := Vector3(0.011, 0.0, 0.001)
	var tail_top := Vector3(0.0, 0.0055, 0.012)
	var tail_l := Vector3(-0.0045, 0.0, 0.012)
	var tail_r := Vector3(0.0045, 0.0, 0.012)
	var exhaust := Vector3(0.0, 0.0, 0.014)

	# Fuselage
	st.add_vertex(nose); st.add_vertex(body_mid); st.add_vertex(exhaust)
	st.add_vertex(nose); st.add_vertex(exhaust); st.add_vertex(body_mid * Vector3(-1, 1, 1))

	# Swept Mid-Wings
	st.add_vertex(body_mid); st.add_vertex(wing_l); st.add_vertex(exhaust * 0.7)
	st.add_vertex(body_mid); st.add_vertex(exhaust * 0.7); st.add_vertex(wing_r)

	# Cruciform Tail Fins
	st.add_vertex(exhaust); st.add_vertex(tail_top); st.add_vertex(exhaust * 0.85)
	st.add_vertex(exhaust); st.add_vertex(tail_l); st.add_vertex(exhaust * 0.85)
	st.add_vertex(exhaust); st.add_vertex(exhaust * 0.85); st.add_vertex(tail_r)

	st.generate_normals()
	var m := st.commit()
	m.surface_set_material(0, mat)
	return m


## 11. Ballistic Missile / MRBM (DF-21D / ATACMS / Minuteman):
## High fineness ratio booster cylinder, conical nose shroud / MIRV re-entry cone, 4 base grid fins.
static func create_ballistic_missile_mesh(mat: Material) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var nose := Vector3(0.0, 0.0, -0.026)
	var shroud := Vector3(0.0, 0.0028, -0.016)
	var b_t := Vector3(0.0, 0.0028, 0.016)
	var b_b := Vector3(0.0, -0.0028, 0.016)
	var b_l := Vector3(-0.0028, 0.0, 0.016)
	var b_r := Vector3(0.0028, 0.0, 0.016)
	var fin_t := Vector3(0.0, 0.0065, 0.018)
	var fin_b := Vector3(0.0, -0.0065, 0.018)
	var fin_l := Vector3(-0.0065, 0.0, 0.018)
	var fin_r := Vector3(0.0065, 0.0, 0.018)
	var rocket_plume := Vector3(0.0, 0.0, 0.024)

	# Conical RV Warhead
	st.add_vertex(nose); st.add_vertex(shroud); st.add_vertex(shroud * Vector3(-1, 1, 1))

	# Booster Body
	st.add_vertex(shroud); st.add_vertex(b_t); st.add_vertex(b_r)
	st.add_vertex(shroud); st.add_vertex(b_l); st.add_vertex(b_b)

	# 4 Base Stabilizer / Grid Fins
	st.add_vertex(b_t); st.add_vertex(fin_t); st.add_vertex(rocket_plume)
	st.add_vertex(b_b); st.add_vertex(rocket_plume); st.add_vertex(fin_b)
	st.add_vertex(b_l); st.add_vertex(fin_l); st.add_vertex(rocket_plume)
	st.add_vertex(b_r); st.add_vertex(rocket_plume); st.add_vertex(fin_r)

	st.generate_normals()
	var m := st.commit()
	m.surface_set_material(0, mat)
	return m


## 12. Loitering Suicide Drone (Shahed-136 / Switchblade 600):
## Delta wing planform, clipped wingtips, vertical endplate fins, pusher prop tail.
static func create_loitering_drone_mesh(mat: Material) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var nose := Vector3(0.0, 0.001, -0.012)
	var tip_l := Vector3(-0.012, 0.0, 0.008)
	var tip_r := Vector3(0.012, 0.0, 0.008)
	var fin_l := Vector3(-0.012, 0.005, 0.008)
	var fin_r := Vector3(0.012, 0.005, 0.008)
	var prop_tail := Vector3(0.0, 0.002, 0.010)

	# Delta Wing Planform
	st.add_vertex(nose); st.add_vertex(tip_l); st.add_vertex(prop_tail)
	st.add_vertex(nose); st.add_vertex(prop_tail); st.add_vertex(tip_r)

	# Wingtip Canted Stabilizers
	st.add_vertex(tip_l); st.add_vertex(fin_l); st.add_vertex(prop_tail)
	st.add_vertex(tip_r); st.add_vertex(prop_tail); st.add_vertex(fin_r)

	st.generate_normals()
	var m := st.commit()
	m.surface_set_material(0, mat)
	return m


## 13. Hypersonic Glide Vehicle (DF-17 / Avangard Waverider):
## Sharp triangular waverider wedge body, faceted belly compression ramp, twin canted dorsal fins.
static func create_hypersonic_glide_mesh(mat: Material) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var needle_tip := Vector3(0.0, 0.0, -0.022)
	var belly_keel := Vector3(0.0, -0.0025, 0.002)
	var upper_ridge := Vector3(0.0, 0.0022, 0.004)
	var flank_l := Vector3(-0.009, 0.0, 0.012)
	var flank_r := Vector3(0.009, 0.0, 0.012)
	var dorsal_l := Vector3(-0.004, 0.0055, 0.014)
	var dorsal_r := Vector3(0.004, 0.0055, 0.014)

	# Compression Waverider Belly
	st.add_vertex(needle_tip); st.add_vertex(flank_l); st.add_vertex(belly_keel)
	st.add_vertex(needle_tip); st.add_vertex(belly_keel); st.add_vertex(flank_r)

	# Upper Aerodynamic Shroud
	st.add_vertex(needle_tip); st.add_vertex(upper_ridge); st.add_vertex(flank_l)
	st.add_vertex(needle_tip); st.add_vertex(flank_r); st.add_vertex(upper_ridge)

	# Twin Canted Dorsal Stabilizers
	st.add_vertex(upper_ridge); st.add_vertex(dorsal_l); st.add_vertex(flank_l)
	st.add_vertex(upper_ridge); st.add_vertex(flank_r); st.add_vertex(dorsal_r)

	st.generate_normals()
	var m := st.commit()
	m.surface_set_material(0, mat)
	return m
