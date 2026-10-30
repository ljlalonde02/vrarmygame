class_name GlobalOrbatSystem
extends RefCounted
## Phase 15 Global 1,000,000-Unit Multi-Theater Order of Battle (ORBAT) & Real-World Unit Designation System.
## Simultaneously tracks and simulates 1,000,000 tactical combat units (~3.45M personnel) across all 7
## 2,000km x 2,000km Global Theaters of War (Ukraine, China/Taiwan, NATO/Baltic, India/Himalaya, Korea,
## US-Mexico Rio Grande, and Strait of Hormuz) with authentic real-world Brigade/Division/Carrier names and bases.

const TOTAL_INITIAL_GLOBAL_UNITS := 1000000

## Returns the initial 1,000,000-unit Global Order of Battle split across all 7 2,000x2,000 km theaters
## with realistic modern army compositions (Infantry/Mech, Drones/Robot Dogs, Artillery/Missiles, Armor/UGV, Air/IADS, Naval/Carriers).
static func create_initial_global_theaters() -> Dictionary:
	return {
		"ukraine_donbas_theater": {
			"slug": "ukraine_donbas_theater",
			"scenario_slug": "op_ukraine_donbas_2028",
			"short_name": "UKRAINE & BLACK SEA",
			"actors": "UKR + NATO vs RUS",
			"lat": 48.0,
			"lon": 35.5,
			"blue_initial": 115000,
			"red_initial": 125000,
			"blue_active": 115000,
			"red_active": 125000,
			"blue_Composition": "60% Mech/Inf (47th Magura, 3rd Assault, 93rd Bde) | 20% FPV/UAV (414th Madyar's Birds, Palianytsia) | 12% Arty/Neptune (2S22 Bohdana, 19th Bde) | 5% Armor (T-84 Oplot, Leopard 2A8) | 3% Air/USV (40th Avn, 385th MAGURA V5)",
			"red_Composition": "56% Motor-Rifle/Assault (8th & 58th CAA) | 20% Lancet/Shahed Swarms | 14% Arty/EW/IADS (S-400, Krasukha-4) | 6% Armor (1st Guards Tank Army T-90M) | 4% VKS/Black Sea Fleet (Adm. Gorshkov, Engels-2 Tu-22M3)",
			"carrier_flagship": "385th USV Flotilla (Odesa) vs Black Sea Fleet Adm. Gorshkov (Sevastopol/Novorossiysk)",
		},
		"strait_theater": {
			"slug": "strait_theater",
			"scenario_slug": "op_pacific_shield_2028",
			"short_name": "CHINA / TAIWAN STRAIT",
			"actors": "USA + TWN vs CHN PLA",
			"lat": 24.2,
			"lon": 120.2,
			"blue_initial": 100000,
			"red_initial": 120000,
			"blue_active": 100000,
			"red_active": 120000,
			"blue_Composition": "42% ROC 6th/8th/10th Corps Mech/Inf | 22% Robot Dog & FPV Swarms | 14% USAF 18th/388th Wing (F-35A, XQ-58, B-21) | 12% Patriot/Iron Beam/Leonidas IADS | 10% USN CSG-12 (USS Gerald R. Ford CVN-78, DDG-51, Orca XLUUV)",
			"red_Composition": "46% PLA 71st/72nd/73rd Group Army Amphib/Mech | 22% Unitree B2-W Robot Dogs & Loitering Swarms | 14% PLAAF Eastern Theater (J-20A) | 10% PLA Rocket Force Base 61 & S-400 | 8% PLAN Task Group 18 (CNS Fujian CV-18, Type 055)",
			"carrier_flagship": "USS Gerald R. Ford (CVN-78) CSG vs PLAN CNS Fujian (CV-18) & CNS Shandong (CV-17)",
		},
		"baltic_suwalki_theater": {
			"slug": "baltic_suwalki_theater",
			"scenario_slug": "op_baltic_shield_suwalki",
			"short_name": "NATO BALTIC / SUWALKI",
			"actors": "EUR_NATO + USA vs RUS + BLR",
			"lat": 54.3,
			"lon": 22.8,
			"blue_initial": 82000,
			"red_initial": 78000,
			"blue_active": 82000,
			"red_active": 78000,
			"blue_Composition": "48% NATO MNC-NE Mech/Inf (Polish 18th Iron Div, Lithuanian Iron Wolf) | 18% Heavy Armor & UGVs (German 45th PzBde Leopard 2A8, M1A2, THeMIS) | 14% NATO Air Policing (Rafale F4, F-35A at Siauliai/Lask) | 12% Skynex/Patriot | 8% FS Charles de Gaulle (R91) CSG",
			"red_Composition": "50% Russian 11th Army Corps & Belarusian WOC Motor-Rifle | 18% 1st Guards Tank Army (T-90M, Uran-9 UGV) | 16% Kaliningrad A2/AD Bastion (S-400, Iskander/Kinzhal, Krasukha-4) | 10% VKS Su-57/Tu-22M3 | 6% Baltic Fleet (Baltiysk)",
			"carrier_flagship": "FS Charles de Gaulle (R91) & HMS Queen Elizabeth vs Baltic Fleet (Kaliningrad)",
		},
		"himalaya_lac_theater": {
			"slug": "himalaya_lac_theater",
			"scenario_slug": "op_himalayan_sentinel_lac",
			"short_name": "INDIA / HIMALAYA LAC",
			"actors": "IND vs CHN + PAK",
			"lat": 34.0,
			"lon": 78.2,
			"blue_initial": 75000,
			"red_initial": 75000,
			"blue_active": 75000,
			"red_active": 75000,
			"blue_Composition": "54% XIV 'Fire & Fury' & XVII 'Brahmastra' Mountain Strike Corps | 18% Cliff-Climbing Robot Dogs & FPV Swarms | 12% 254th Armoured Bde (Zorawar Light Tank) & BrahMos Batteries | 10% IAF Ambala/Leh (Rafale, Tejas Mk2) | 6% INS Vikrant (R11) CBG",
			"red_Composition": "52% PLA Western Theater (76th/77th GA) & Pak X Corps Mountain Inf | 20% Unitree B2-W Robot Dogs & Akinci UCAVs | 14% PLAAF Hotan/Ngari (J-20A) & PAF No. 28 Sq Skardu (JF-17 Block III) | 14% S-400 & Rocket Arty",
			"carrier_flagship": "INS Vikrant (R11) & INS Vikramaditya vs PLAN/PN Northern Arabian Sea Task Force",
		},
		"korean_dmz_theater": {
			"slug": "korean_dmz_theater",
			"scenario_slug": "op_korean_thunder_dmz",
			"short_name": "KOREAN PENINSULA DMZ",
			"actors": "KOR + USA vs PRK",
			"lat": 38.0,
			"lon": 127.2,
			"blue_initial": 52000,
			"red_initial": 58000,
			"blue_active": 52000,
			"red_active": 58000,
			"blue_Composition": "48% ROK VII Maneuver Corps ('Fierce Tiger') & US 2nd ID Mech | 18% K2 Black Panther Mountain Armor & Vision 60 Dogs | 14% Strategic Strike (Hyunmoo-5, Patriot, Iron Beam) | 12% ROKAF 17th Wing (KF-21, F-35A at Osan/Cheongju) | 8% ROKS Jeongjo the Great",
			"red_Composition": "54% KPA II & IV Corps Forward Infantry | 22% Missile General Bureau (KN-25 600mm Super-Large MLRS) & Koksan Arty | 14% 105th Ryu Kyong-su Tank Div | 10% Loitering Drone Swarms & Sunchon Underground Air Wing",
			"carrier_flagship": "ROKS Jeongjo the Great (DDG-995) & Busan Task Flotilla vs Wonsan/Nampo Littoral",
		},
		"mexico_rio_grande_theater": {
			"slug": "mexico_rio_grande_theater",
			"scenario_slug": "op_mexico_rio_grande_2028",
			"short_name": "US-MEXICO RIO GRANDE",
			"actors": "USA NORTHCOM vs MEX SEDENA",
			"lat": 26.2,
			"lon": -99.2,
			"blue_initial": 36000,
			"red_initial": 34000,
			"blue_active": 36000,
			"red_active": 34000,
			"blue_Composition": "46% US III Armored Corps (1st Cavalry Div & 1st Armored Div at Fort Cavazos/Laredo) | 20% Stryker Leonidas HPM & Vision 60 Robot Dogs | 18% USAF ACC (JBSA Kelly F-35A, F-16V, MQ-28) | 16% US 4th Fleet Gulf Group (NAS Corpus Christi DDG-51)",
			"red_Composition": "52% SEDENA IV & II Region Militar + Brigada de Fusileros Paracaidistas | 22% 1/a Brigada Blindada (DN-XI & ERC-90 Lynx Cavalry) | 14% Fuerzas Especiales Mountain & FPV Teams (Sierra Madre) | 6% FAM Escuadron 401 (BAM-1 Santa Lucia / BAM-14 Monterrey F-5F) | 6% SEMAR ARM Benito Juarez (POLA-101)",
			"carrier_flagship": "US 4th Fleet Corpus Christi Strike Group vs SEMAR ARM Benito Juarez (POLA-101) Flotilla",
		},
		"hormuz_theater": {
			"slug": "hormuz_theater",
			"scenario_slug": "op_red_strait_swarm",
			"short_name": "STRAIT OF HORMUZ / GULF",
			"actors": "USA 5TH FLEET vs IRN IRGC",
			"lat": 26.2,
			"lon": 56.4,
			"blue_initial": 25000,
			"red_initial": 25000,
			"blue_active": 25000,
			"red_active": 25000,
			"blue_Composition": "34% US 5th Fleet CSG (USS Abraham Lincoln CVN-72, DDG-51, Orca XLUUV at Fujairah/Bahrain) | 28% Task Force 59 Autonomous USVs | 22% USAF 380th AEW (Al Dhafra F-35A, B-21 Raider) | 16% Khasab Patriot & Iron Beam Laser Bastion",
			"red_Composition": "44% IRGC Navy 1st Region Fast-Boat & Kamikaze USV Wolfpacks (Bandar Abbas/Jask) | 30% IRGC Aerospace Force (Qeshm Shahed-136 & Anti-Ship Cruise Batteries) | 16% Zagros S-400/Bavar-373 IADS | 10% Artesh 9th Tactical Airbase",
			"carrier_flagship": "USS Abraham Lincoln (CVN-72) 5th Fleet CSG vs IRGC 1st Naval Region (Bandar Abbas)",
		},
	}


## Advances all 7 Global Theaters in parallel. The currently active 3D War Table theater syncs directly
## with `WorldState` attrition, while the other 6 Global Theaters integrate continuous Lanchester attrition.
static func step_global_orbat(state: WorldState, dt: float) -> void:
	if state.global_theaters.is_empty():
		state.global_theaters = create_initial_global_theaters()

	var total_blue := 0
	var total_red := 0
	var active_slug := state.active_theater_slug

	# Compute active theater live survival ratios from WorldState
	var active_b_alive := 0
	var active_r_alive := 0
	var active_b_total := 0
	var active_r_total := 0
	for uid in range(state.unit_count):
		if state.unit_echelon[uid] != WorldState.ECHELON_COMPANY:
			continue
		if state.unit_faction[uid] == WorldState.FACTION_BLUE:
			active_b_total += 1
			if state.unit_active[uid] == 1:
				active_b_alive += 1
		else:
			active_r_total += 1
			if state.unit_active[uid] == 1:
				active_r_alive += 1

	var idx := 0
	for t_slug in state.global_theaters.keys():
		var t_data: Dictionary = state.global_theaters[t_slug]
		var b_init: int = int(t_data["blue_initial"])
		var r_init: int = int(t_data["red_initial"])

		if t_slug == active_slug and active_b_total > 0 and active_r_total > 0:
			var b_ratio := float(active_b_alive) / float(active_b_total)
			var r_ratio := float(active_r_alive) / float(active_r_total)
			t_data["blue_active"] = maxi(0, int(round(float(b_init) * b_ratio)))
			t_data["red_active"] = maxi(0, int(round(float(r_init) * r_ratio)))
		else:
			# Background Lanchester attrition across out-of-focus global theaters (~0.015% per second)
			var b_cur := float(t_data["blue_active"])
			var r_cur := float(t_data["red_active"])
			var phase := sin(state.sim_time_sec * 0.25 + float(idx) * 1.3)
			var b_loss := r_cur * 0.00012 * dt * (1.0 - 0.18 * phase)
			var r_loss := b_cur * 0.00013 * dt * (1.0 + 0.18 * phase)
			t_data["blue_active"] = maxi(int(float(b_init) * 0.35), int(b_cur - b_loss))
			t_data["red_active"] = maxi(int(float(r_init) * 0.35), int(r_cur - r_loss))

		total_blue += int(t_data["blue_active"])
		total_red += int(t_data["red_active"])
		idx += 1

	state.global_blue_units_active = total_blue
	state.global_red_units_active = total_red
	state.global_total_units_active = total_blue + total_red

	# Compute global 7-theater casualties (KIA/WIA) & ammunition expended from unit attrition across all theaters
	var g_blue_lost_units := maxi(0, 485000 - total_blue)
	var g_red_lost_units := maxi(0, 515000 - total_red)
	state.global_blue_kia = state.blue_personnel_kia + g_blue_lost_units * 3
	state.global_blue_wia = state.blue_personnel_wia + g_blue_lost_units * 7
	state.global_red_kia = state.red_personnel_kia + g_red_lost_units * 3
	state.global_red_wia = state.red_personnel_wia + g_red_lost_units * 7
	state.global_blue_ammo_expended = state.blue_munitions_expended + g_red_lost_units * 6
	state.global_red_ammo_expended = state.red_munitions_expended + g_blue_lost_units * 6


## Returns an authentic real-world historical/current Military Unit Designation, Parent Formation,
## and Home Base for any unit in the active theater based on Web-verified Orders of Battle.
static func get_authentic_unit_designation(theater_slug: String, faction: int, domain: String, unit_class: String, uid: int) -> String:
	var is_blue := (faction == WorldState.FACTION_BLUE)
	var slot := absi(uid) % 6

	if theater_slug.find("ukraine") != -1 or theater_slug.find("donbas") != -1:
		if is_blue:
			if domain == "AIR":
				var air_u := [
					"40th Tactical Aviation Bde 'Ghost of Kyiv' (Myrhorod AB)",
					"7th Tactical Aviation Bde (Starokostiantyniv AB)",
					"39th Tactical Aviation Bde (Ozerne AB)",
					"414th Separate Strike UAV Bde 'Madyar's Birds'",
				]
				return air_u[slot % air_u.size()]
			elif domain == "SEA":
				return "385th Separate USV Naval Brigade (Odesa Naval Base)"
			elif unit_class in ["SWARM_TEAM", "ROBOT_DOG", "UGV"]:
				var uav_u := [
					"414th Unmanned Systems Bde 'Madyar's Birds' (Pokrovsk)",
					"92nd Assault Bde 'Achilles' Drone Bn (Kharkiv-Donbas)",
					"3rd Assault Brigade 'Terra' Reconnaissance Drone Group",
				]
				return uav_u[slot % uav_u.size()]
			elif unit_class in ["HYPERSONIC_TEL", "SAM", "CUAS_GUN"]:
				var art_u := [
					"19th Missile Brigade 'Saint Barbara' (Neptune / Vilkha)",
					"43rd Separate Artillery Brigade (2S22 Bohdana 155mm)",
					"96th Kyiv Anti-Aircraft Missile Brigade (Patriot PAC-3)",
				]
				return art_u[slot % art_u.size()]
			var gnd_u := [
				"47th Mechanized Brigade 'Magura' (Zaporizhzhia / Pokrovsk)",
				"3rd Separate Assault Brigade (Donbas Eastern Front)",
				"93rd Mechanized Brigade 'Kholodnyi Yar' (Kramatorsk)",
				"1st Tank Brigade 'Siversk' (T-84 Oplot-M / Leopard 2A8)",
				"80th Air Assault Brigade 'Galician' (BTR-4E Bucephalus)",
				"36th Separate Marine Brigade (Mykolaiv / Dnipro)",
			]
			return gnd_u[slot % gnd_u.size()]
		else:
			if domain == "AIR":
				var r_air := [
					"VKS 22nd Guards Heavy Bomber Div (Engels-2 Airbase)",
					"4th Air & Air Defense Forces Army (Millerovo / Rostov)",
					"31st Guards Fighter Aviation Regiment (Su-57 / Millerovo)",
				]
				return r_air[slot % r_air.size()]
			elif domain == "SEA":
				return "Black Sea Fleet — 30th Surface Ship Div (Sevastopol / Novorossiysk)"
			var r_gnd := [
				"8th Guards Combined Arms Army (Donetsk Axis)",
				"58th Combined Arms Army (Zaporizhzhia / Tokmak)",
				"1st Guards Tank Army — 4th 'Kantemirovskaya' Tank Div",
				"2nd Guards 'Tamanskaya' Motor-Rifle Division",
				"76th Guards Air Assault Division (VDV Pskov)",
				"18th Combined Arms Army (Crimea / Left-Bank Dnipro)",
			]
			return r_gnd[slot % r_gnd.size()]

	elif theater_slug.find("mexico") != -1 or theater_slug.find("rio_grande") != -1:
		if is_blue:
			if domain == "AIR":
				var m_air := [
					"USAF 388th Fighter Wing Det. (JBSA Kelly / Lackland, TX)",
					"USAF 49th Wing (Holloman / Rio Grande Air Sector)",
					"USAF 7th Bomb Wing (Dyess AFB / Texas Strategic Orbit)",
				]
				return m_air[slot % m_air.size()]
			elif domain == "SEA":
				return "US 4th Fleet — CSG-12 USS Gerald R. Ford (NAS Corpus Christi)"
			var m_gnd := [
				"US III Armored Corps — 1st Cavalry Div 'First Team' (Fort Cavazos)",
				"1st Armored Division 'Old Ironsides' (Fort Bliss / Laredo)",
				"3rd Cavalry Regiment 'Brave Rifles' (Stryker HPM, Rio Grande)",
				"75th Ranger Regiment & Vision 60 Robot Dog Vanguard",
				"32nd Army Air & Missile Defense Command (Fort Bliss Patriot)",
			]
			return m_gnd[slot % m_gnd.size()]
		else:
			if domain == "AIR":
				var mx_air := [
					"FAM Escuadrón Aéreo 401 (BAM No. 1 Santa Lucía — F-5E/F)",
					"FAM Escuadrón Aéreo 202 (BAM No. 14 Monterrey Apodaca)",
					"FAM Escuadrón de Vigilancia Aérea (Northern Radar Net)",
				]
				return mx_air[slot % mx_air.size()]
			elif domain == "SEA":
				return "SEMAR Fuerza Naval del Golfo — ARM Benito Juárez (POLA-101, Veracruz/Tampico)"
			var mx_gnd := [
				"SEDENA 1/a Brigada Blindada (1st Armored Bde — DN-XI / Lynx)",
				"IV Región Militar (Monterrey Sierra Madre Oriental HQ)",
				"Brigada de Fusileros Paracaidistas (Parachute Rifle Bde)",
				"Cuerpo de Fuerzas Especiales (Sierra Madre Mountain Recon)",
				"II Región Militar Mechanized Cavalry (Northern Frontier)",
			]
			return mx_gnd[slot % mx_gnd.size()]

	elif theater_slug.find("baltic") != -1 or theater_slug.find("suwalki") != -1:
		if is_blue:
			if domain == "AIR":
				return "NATO Baltic Air Policing — Siauliai (LTU) & Lask (POL)"
			elif domain == "SEA":
				return "NATO Task Group — FS Charles de Gaulle (R91, Klaipeda/Gdynia)"
			var b_gnd := [
				"German 45th Armored Brigade 'Litauen' (Rukla, Lithuania)",
				"Polish 18th Mechanized Division 'Iron Division' (Suwalki)",
				"NATO Multinational Corps Northeast (Szczecin / Bialystok)",
				"Lithuanian 'Iron Wolf' Mechanized Infantry Brigade",
				"US V Corps Forward — 2nd Cavalry Regiment (Bemowo Piskie)",
			]
			return b_gnd[slot % b_gnd.size()]
		else:
			if domain == "AIR":
				return "VKS 689th Guards Fighter Regt (Chkalovsk Airbase, Kaliningrad)"
			elif domain == "SEA":
				return "Russian Baltic Fleet — 128th Surface Brigade (Baltiysk)"
			var rb_gnd := [
				"Russian 11th Army Corps (Kaliningrad Bastion)",
				"1st Guards Tank Army (Western MD / Grodno Axis)",
				"336th Separate Guards Naval Infantry Bde (Kaliningrad)",
				"152nd Guards Missile Brigade (Iskander/S-400 Chernyakhovsk)",
				"Belarusian Western Operational Command — 11th Mech Bde (Grodno)",
			]
			return rb_gnd[slot % rb_gnd.size()]

	elif theater_slug.find("himalaya") != -1 or theater_slug.find("lac") != -1:
		if is_blue:
			if domain == "AIR":
				return "IAF No. 17 Squadron 'Golden Arrows' (Ambala & Leh AFS)"
			elif domain == "SEA":
				return "Indian Navy Western Fleet — INS Vikrant (R11) Carrier Battle Group"
			var i_gnd := [
				"Indian Army XIV Corps 'Fire and Fury' (Leh, Ladakh)",
				"XVII Mountain Strike Corps 'Brahmastra' (Pangong / Rezang La)",
				"254th Armoured Brigade (Zorawar Light Tanks, Daulat Beg Oldi)",
				"3rd Infantry Division 'Trishul' (Eastern Ladakh LAC)",
				"Strategic Forces BrahMos PJ-10 Regiment (Karakoram Pass)",
			]
			return i_gnd[slot % i_gnd.size()]
		else:
			if domain == "AIR":
				var hi_air := [
					"PLAAF Western Theater — 111th Air Brigade (Hotan & Ngari Gunsa)",
					"PAF No. 28 Squadron 'Phoenix' (JF-17 Block III, PAF Base Skardu)",
					"PAF No. 15 Squadron 'Cobras' (Minhas Kamra Airbase)",
				]
				return hi_air[slot % hi_air.size()]
			var hi_gnd := [
				"PLA Western Theater — 76th Group Army (Aksai Chin)",
				"PLA 77th Group Army & South Xinjiang MD (6th Highland Mech Div)",
				"Pakistan Army X Corps — Force Command Northern Areas (Gilgit/Skardu)",
				"PLA Highland Quadruped Robot Dog & Loitering Swarm Detachment",
			]
			return hi_gnd[slot % hi_gnd.size()]

	elif theater_slug.find("korea") != -1:
		if is_blue:
			if domain == "AIR":
				return "ROKAF 17th Fighter Wing (Cheongju) & US 7th AF (Osan AB)"
			elif domain == "SEA":
				return "ROK Navy Maritime Task Flotilla 7 — ROKS Jeongjo the Great (Busan)"
			var k_gnd := [
				"ROK VII Maneuver Corps 'Vanguard' — Capital Mech Div 'Fierce Tiger'",
				"ROK 11th Maneuver Division 'Hwarang' (K2 Black Panther, Chorwon)",
				"US 2nd Infantry Division / ROK-US Combined Division (Camp Humphreys)",
				"ROK Strategic Command — Hyunmoo-5 Bunker-Buster Missile Bde",
			]
			return k_gnd[slot % k_gnd.size()]
		else:
			if domain == "AIR":
				return "KPA 1st Air & Anti-Air Division (Sunchon Underground Airbase)"
			var rk_gnd := [
				"KPA II Corps (Kaesong-Chorwon Forward DMZ)",
				"KPA 105th Ryu Kyong-su Guards Seoul Tank Division",
				"KPA Missile General Bureau — 600mm KN-25 Super-Large MLRS Regt",
				"KPA IV Corps (Hwanghae Littoral & Drone Assault Group)",
			]
			return rk_gnd[slot % rk_gnd.size()]

	elif theater_slug.find("hormuz") != -1:
		if is_blue:
			if domain == "AIR":
				return "USAF 380th Air Expeditionary Wing (Al Dhafra AB, UAE)"
			elif domain == "SEA":
				return "US 5th Fleet — USS Abraham Lincoln (CVN-72) & TF-59 (Fujairah/Bahrain)"
			return "Coalition Musandam Defense Command (Khasab Patriot & Iron Beam Hub)"
		else:
			if domain == "AIR":
				return "IRIAF 9th Tactical Airbase (Bandar Abbas) & IRGC Drone Command"
			elif domain == "SEA":
				return "IRGC Navy 1st Naval Region Fast-Attack Wolfpack (Bandar Abbas / Jask)"
			return "IRGC Aerospace Force Coastal Citadel (Qeshm Island & Zagros)"

	# Default: China / Taiwan Strait (`strait_theater`)
	if is_blue:
		if domain == "AIR":
			var st_air := [
				"USAF 18th & 388th Fighter Wing (Kadena AB, Okinawa)",
				"ROCAF 2nd Tactical Fighter Wing (Hsinchu Airbase)",
				"ROCAF 4th Tactical Fighter Wing (Chiayi Airbase)",
			]
			return st_air[slot % st_air.size()]
		elif domain == "SEA":
			var st_sea := [
				"US 7th Fleet — CSG-12 USS Gerald R. Ford (CVN-78) & DESRON 15",
				"ROC Navy 124th Fleet & Autonomous USV Flotilla (Zuoying / Kaohsiung)",
			]
			return st_sea[slot % st_sea.size()]
		var st_gnd := [
			"ROC 6th Army Corps — 542nd Armored Brigade (Hsinchu / Taipei)",
			"ROC 10th Army Corps — 586th Armored Brigade (Taichung / Yushan)",
			"ROC 8th Army Corps — 333rd Mechanized Bde (Kaohsiung)",
			"USMC 3rd Marine Littoral Regiment & Vision 60 Robot Dog Vanguard",
			"1st Multi-Domain Task Force (LRHW Dark Eagle & Iron Beam Battery)",
		]
		return st_gnd[slot % st_gnd.size()]
	else:
		if domain == "AIR":
			var cn_air := [
				"PLAAF Eastern Theater — 9th Air Brigade (J-20A, Wuhu / Fuzhou AB)",
				"PLAAF 14th Air Division (Longtian Forward Airbase, Fujian)",
				"PLAAF 10th Bomber Division (Anqing / Eastern Strike Group)",
			]
			return cn_air[slot % cn_air.size()]
		elif domain == "SEA":
			var cn_sea := [
				"PLAN Carrier Task Group 18 — CNS Fujian (CV-18) & Type 055 Escorts",
				"PLAN Carrier Task Group 17 — CNS Shandong (CV-17, Yulin / Taiwan Strait)",
				"PLAN East Sea Fleet — 3rd Destroyer Flotilla (Zhoushan / Xiamen)",
			]
			return cn_sea[slot % cn_sea.size()]
		var cn_gnd := [
			"PLA Eastern Theater — 73rd Group Army, 14th Amphibious Bde (Xiamen)",
			"PLA 72nd Group Army — 5th Amphibious Combined Arms Bde (Huzhou)",
			"PLA 71st Group Army — 2nd Heavy Combined Arms Bde (Xuzhou)",
			"PLA Rocket Force Base 61 (Huangshan / Longtian Hypersonic & S-400)",
			"PLA Unmanned Assault Detachment (Unitree B2-W Robot Dogs & Swarms)",
		]
		return cn_gnd[slot % cn_gnd.size()]
