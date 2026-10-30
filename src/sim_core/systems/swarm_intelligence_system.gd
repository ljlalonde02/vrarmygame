class_name SwarmIntelligenceSystem
extends RefCounted
## Phase 36: Multi-Domain Swarm Intelligence & Pack Autonomy Engine (C4ISR / CEC):
## - Coordinates 4-Ship Fighter Flights, 4-Tank Platoons, 8-Robot Dog Packs, and USV Wolfpacks:
##   1. Target Deconfliction & Anti-Overkill Allocation (Units coordinate to avoid targeting the same enemy).
##   2. Cooperative Multi-Axis Flanking (Lead element fixes target while wingmen pincer from 45°-90° azimuth).
##   3. Sensor Mesh Illuminator & Silent Hunters (One unmanned drone radiates radar while stealth wingmen stay silent).
##   4. Detailed Platform Qualities & Flaws (Forces et Faiblesses: Stealth vs Thermal Bloom, Agility vs Armor, Fuel vs Speed).

const TACTICAL_ROLE_LEAD := 0
const TACTICAL_ROLE_WINGMAN_FLANK := 1
const TACTICAL_ROLE_ILLUMINATOR := 2
const TACTICAL_ROLE_OVERWATCH := 3

## Registry of authentic platform qualities (Forces) and flaws/vulnerabilities (Faiblesses)
const PLATFORM_PROS_CONS: Dictionary = {
	"f_35a_lightning": {
		"pros": ["RCS Ultra-Furtive (0.0015 m²)", "Fusion Capteurs 6-Spectres", "Liaison MADL/CEC"],
		"cons": ["Soute interne limitée (4 AIM-120)", "Panache thermique en postcombustion", "Rayon d'action sans ravitailleur"],
		"swarm_role": "Coordinateur Furtif & Désignateur Silencieux"
	},
	"j_20_mighty_dragon": {
		"pros": ["Vitesse de pointe Mach 2.2", "Missiles très longue portée PL-15 (200 km)", "Grand rayon d'action"],
		"cons": ["RCS arrière et latéral plus élevé", "Inertie importante en virage serré", "Dépendance au radar lourd"],
		"swarm_role": "Intercepteur BVR Lourd & Casseur de Ravitailleurs"
	},
	"su_57_felon": {
		"pros": ["Super-manœuvrabilité poussée vectorielle 3D", "Radar bande L anti-furtivité", "Canon 30mm létal"],
		"cons": ["RCS supérieur aux avions occidentaux (0.1 m²)", "Production en série limitée", "Émissions radar traçables"],
		"swarm_role": "Chasseur de Supériorité Rapprochée"
	},
	"xq_58a_valkyrie": {
		"pros": ["Drone Loyal Wingman bon marché", "Sacrifiable en première ligne", "Emport modulable"],
		"cons": ["Autonomie de calcul IA réduite", "Vitesse subsonique", "Vulnérable aux tirs de canon"],
		"swarm_role": "Appât Actif & Éclaireur Radar Déporté"
	},
	"vision_60_q_ugv": {
		"pros": ["Escalade pentes abruptes (>30°)", "Silencieux et indétectable au radar", "Insensible au brouillage RF"],
		"cons": ["Blindage léger", "Batterie limitée", "Vitesse réduite en terrain plat"],
		"swarm_role": "Infiltration de Falaise & Désignation Laser JTAC"
	},
	"m1a2_sepv3_platoon": {
		"pros": ["Blindage uranium appauvri + Trophy APS", "Puissance de feu 120mm M829A4", "Système C4ISR FBCB2"],
		"cons": ["Masse extrême (73 tonnes)", "Consommation turbine vorace", "Vulnérable aux drones FPV de toit"],
		"swarm_role": "Pivot de Rupture Blindée Frontale"
	},
	"type_055_renhai": {
		"pros": ["112 silos VLS polyvalents", "Radar double bande S/X", "Capacité hypersonique YJ-21"],
		"cons": ["Silhouette radar gigantesque", "Cible prioritaire n°1", "Vulnérable aux meutes sous-marines"],
		"swarm_role": "Bâtiment Amiral & Dôme Anti-Aérien de Théâtre"
	},
	"ddg_51_arleigh_burke": {
		"pros": ["Système de combat Aegis Baseline 10", "Intercepteurs SM-6 / SM-3", "Torpilles et guerre ASM"],
		"cons": ["Capacité VLS saturable", "Signature infrarouge élevée", "Coût de remplacement majeur"],
		"swarm_role": "Défense Aérienne et Anti-Missile de Zone"
	},
	"ssn_688i_los_angeles": {
		"pros": ["Silence acoustique sous thermocline", "Torpilles Mk 48 ADCAP filoguidées", "Missiles VLS Tomahawk"],
		"cons": ["Vitesse limitée en plongée silencieuse (5 kts)", "Angle mort arrière du sonar (baffle)", "Pas de défense antiaérienne"],
		"swarm_role": "Chasseur-Tueur Sous-Marin Discret"
	},
	"magura_v5_usv": {
		"pros": ["Furtivité nautique au ras de l'eau", "Charge militaire explosive 320 kg", "Attaque en meute coordonnée"],
		"cons": ["Sensible à la houle (Beaufort > 5)", "Vulnérable aux mitrailleuses de pont", "Dépendance au relais satellite"],
		"swarm_role": "Meute Kamikaze de Saturation Navale"
	}
}


## Returns the pros, cons, and tactical swarm role for any platform slug.
static func get_platform_profile(slug: String) -> Dictionary:
	if PLATFORM_PROS_CONS.has(slug):
		return PLATFORM_PROS_CONS[slug]
	for k in PLATFORM_PROS_CONS:
		if slug.contains(k) or k.contains(slug):
			return PLATFORM_PROS_CONS[k]
	return {
		"pros": ["Polyvalence opérationnelle standard"],
		"cons": ["Pas de capacité de pointe spécifique"],
		"swarm_role": "Unité de Soutien de Ligne"
	}


static func get_platform_nuance(slug: String) -> Dictionary:
	var prof := get_platform_profile(slug)
	return {
		"pros": prof.get("pros", []),
		"cons": prof.get("cons", []),
		"qualities": prof.get("pros", []),
		"flaws": prof.get("cons", []),
		"swarm_role": prof.get("swarm_role", "Standard")
	}


## Executes Swarm Intelligence tick across all hierarchical units (Flights, Platoons, Packs, Wolfpacks).
## Coordinates target distribution, multi-axis flanking, and bait-and-hook tactics.
static func step_swarm_intelligence(state: WorldState, sim_db: Node, grid: SpatialHashGrid, dt: float) -> void:
	var n_units := state.unit_count
	var u_act := state.unit_active
	var u_ech := state.unit_echelon
	var u_pid := state.unit_platform_id
	var u_fac := state.unit_faction
	var u_pos := state.unit_pos
	var u_par := state.unit_parent_id

	# Group leaf companies by operational parent (Battalion / Squadron / Wolfpack)
	var swarms_by_parent: Dictionary = {}
	for uid in range(n_units):
		if u_act[uid] == 0 or u_ech[uid] != WorldState.ECHELON_COMPANY:
			continue
		var par_id: int = u_par[uid]
		if par_id < 0:
			par_id = uid # Self-led pack
		var list: Array = swarms_by_parent.get(par_id, [])
		list.append(uid)
		swarms_by_parent[par_id] = list

	# Process collective decision-making for each tactical swarm
	for par_id in swarms_by_parent:
		var members: Array = swarms_by_parent[par_id]
		if members.size() < 2:
			continue # Single unit behaves via standard leaf AI

		var lead_uid: int = members[0]
		var fac: int = u_fac[lead_uid]
		var enemy_fac: int = WorldState.FACTION_RED if fac == WorldState.FACTION_BLUE else WorldState.FACTION_BLUE
		var lead_pos: Vector3 = u_pos[lead_uid]

		# 1. Swarm Sensor Fusion: Find all hostile targets detected by ANY swarm member within 85 km
		var target_scratch: Array[int] = []
		for m_uid in members:
			var m_pos: Vector3 = u_pos[m_uid]
			var found_cnt := grid.query_enemy_units_into_scratch(enemy_fac, m_pos.x, m_pos.z, 75.0)
			var s_uids := grid.scratch_uids
			for s_i in range(found_cnt):
				var h_uid: int = s_uids[s_i]
				if u_act[h_uid] == 1 and not target_scratch.has(h_uid):
					target_scratch.append(h_uid)

		if target_scratch.is_empty():
			continue # No shared targets, swarm maintains cruising formation

		# Sort targets by distance to swarm center
		target_scratch.sort_custom(func(a: int, b: int):
			return lead_pos.distance_squared_to(u_pos[a]) < lead_pos.distance_squared_to(u_pos[b])
		)

		# 2. Deconflict Targets & Assign Multi-Axis Flanking Vectors
		var num_targets := target_scratch.size()
		var p_dom: PackedByteArray = sim_db.plat_domain_id

		for idx in range(members.size()):
			var m_uid: int = members[idx]
			# If player gave direct manual waypoints recently, respect direct order
			if state.unit_player_override_timer[m_uid] > 0.0:
				continue

			var pid: int = u_pid[m_uid]
			var dom_id: int = p_dom[pid] if (pid > 0 and pid < p_dom.size()) else 0
			var assigned_target_uid: int = target_scratch[idx % num_targets]
			var t_pos: Vector3 = u_pos[assigned_target_uid]

			# Swarm Role 0: Lead element charges target head-on (Attracts attention / Illuminates)
			if idx == 0:
				if dom_id == 1: # Air
					state.unit_target_pos[m_uid] = Vector3(t_pos.x, maxf(8800.0, t_pos.y), t_pos.z)
					state.unit_has_waypoint[m_uid] = 1
					state.unit_radar_active[m_uid] = 1 # Illuminator
				elif dom_id == 2: # Naval
					state.unit_target_pos[m_uid] = Vector3(t_pos.x, 0.0, t_pos.z)
					state.unit_has_waypoint[m_uid] = 1

			# Swarm Role 1 & 2: Wingmen execute a 45° to 90° Pincer Flanking Vector
			elif idx in [1, 2]:
				var to_target := Vector2(t_pos.x - lead_pos.x, t_pos.z - lead_pos.z).normalized()
				var flank_sign: float = 1.0 if idx == 1 else -1.0
				# Perpendicular flanking vector
				var perp := Vector2(-to_target.y, to_target.x) * (18.0 * flank_sign)
				var flank_pos_2d := Vector2(t_pos.x, t_pos.z) + perp * 0.75 - to_target * 12.0
				var alt := 9800.0 if dom_id == 1 else 0.0
				state.unit_target_pos[m_uid] = Vector3(flank_pos_2d.x, alt, flank_pos_2d.y)
				state.unit_has_waypoint[m_uid] = 1
				# Wingmen maintain radar silence (EMCON) to sneak in undetected on enemy flank
				if dom_id == 1 and state.unit_tactical_posture[m_uid] != WorldState.TACTICAL_POSTURE_AGGRESSIVE_PURSUIT:
					state.unit_radar_active[m_uid] = 0

			# Swarm Role 3+: High-Altitude / Rear Overwatch & Stand-Off Munition Launch
			else:
				var rear_pos_2d := Vector2(t_pos.x, t_pos.z) - Vector2(t_pos.x - lead_pos.x, t_pos.z - lead_pos.z).normalized() * 32.0
				var alt := 11500.0 if dom_id == 1 else 0.0
				state.unit_target_pos[m_uid] = Vector3(rear_pos_2d.x, alt, rear_pos_2d.y)
				state.unit_has_waypoint[m_uid] = 1
