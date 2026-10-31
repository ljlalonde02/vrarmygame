class_name UnitTacticalTrialsSystem
extends RefCounted
## Authoritative Unit Tactical Trials & Proving Ground Engine (67 Platforms):
## For every platform in the wargame, defines a realistic tactical trial (mini-mission) showcasing:
## 1. How it acts and moves (Mach, knots, altitude envelope, terrain hugging, silent running).
## 2. How it fights (offensive weapon envelope, lead pursuit, BVR lofting, wire guidance, top attack).
## 3. How it defends (chaff/flares, Trophy APS, reactive armor, thermal layer diving, emergency blow).
## 4. Its "Special Trick" against its specific enemy counter-part.
## 5. How it integrates with friendlies and collective swarm intelligence (MADL/CEC, deconfliction, buddy lasing).

const TRIALS_DATA: Dictionary = {
	# =========================================================================
	# 1. 5TH-GEN & 4.5TH-GEN AIR SUPERIORITY & MULTIROLE FIGHTERS
	# =========================================================================
	"f_35a_lightning": {
		"title": "F-35A Lightning II : Infiltration Passive & Frappe Déportée SEAD",
		"domain": "AIR",
		"enemy_category": "Systèmes IADS & Radars Stratégiques (S-400 / HQ-9)",
		"opposing_threat": "s_400_triumf",
		"friendly_partner": "xq_58a_valkyrie",
		"move_act": "Transit furtif Mach 0.92 à 11 500m. Virage 'crank' à 50° pour réduire l'exposition radar tout en maintenant le faisceau MADL dirigé vers l'objectif.",
		"fight": "Tir BVR passif de missiles AIM-120D à 140km sur coordonnées coordonnées, suivi d'une bombe planante furtive AGM-158B JASSM-ER contre le radar d'engagement.",
		"defend": "Alerte optique 360° par capteurs DAS AN/AAQ-37. Éjection séquentielle de paillettes et leurres thermiques, plongeon évasif TBA à 150m pour masquer la signature au sol.",
		"special_trick": "Triangulation ESM Passive : Géolocalise les émetteurs radars ennemis sans jamais émettre un seul photon radar actif (silence RF absolu).",
		"friendly_integration": "Datalink furtif MADL / CEC : Transmet en temps réel les coordonnées de tir aux ailiers sans qu'ils aient besoin d'activer leurs propres radars."
	},
	"j_20_mighty_dragon": {
		"title": "J-20A Mighty Dragon : Interception BVR Haute Vitesse & Chasseur d'AWACS",
		"domain": "AIR",
		"enemy_category": "Multiplicateurs de Force Aériens (E-3G AWACS / KC-46 Ravitailleurs)",
		"opposing_threat": "e_3_sentry_awacs",
		"friendly_partner": "su_57_felon",
		"move_act": "Super-croisière à Mach 1.6 à 13 800m. Pénétration rectiligne à très haute vitesse pour traverser les bulles de détection avant réaction.",
		"fight": "Soute ventrale emportant 4 missiles très longue portée PL-15 à guidage radar AESA actif (portée 200 km) visant le centre névralgique AWACS.",
		"defend": "Leurres remorqués actifs, brouillage ECM en bande X/Ku et manœuvre de rupture transsonique en piqué.",
		"special_trick": "Tir BVR 'Sniper d'AWACS' : Priorise algorithmiquement les nœuds de commandement et de ravitaillement pour aveugler tout le théâtre d'opérations adverse.",
		"friendly_integration": "Réseau IJND tactique : Partage l'image radar globale avec les chasseurs J-16 et JF-17 en seconde ligne."
	},
	"su_57_felon": {
		"title": "Su-57 Felon : Combat Tournoyant Rapproché & Furtivité Latérale",
		"domain": "AIR",
		"enemy_category": "Chasseurs de Supériorité Aérienne (F-15EX / F-22 / Rafale)",
		"opposing_threat": "f_16cj_block70",
		"friendly_partner": "s_70_okhotnik",
		"move_act": "Poussée vectorielle 3D Saturn AL-41F1. Capacité de manœuvres post-décrochage (Cobra de Pougatchev, virage Herbst à rayon nul).",
		"fight": "Combinaison BVR K-77M (antenne AESA en soute) et combat rapproché canon 30mm GSh-30-1 avec viseur de casque Sh-121.",
		"defend": "Brouilleurs infrarouges directionnels DIRCM montés sur le fuselage aveuglant les autodirecteurs thermiques des missiles ennemis.",
		"special_trick": "Super-Maniabilité Post-Décrochage : Annule instantanément la distance minimale d'engagement en virant de 180° sur place pour tirer un R-73 arrière.",
		"friendly_integration": "Liaison bidirectionnelle avec le drone lourd S-70 Okhotnik qui opère comme bouclier avant et réservoir de missiles."
	},
	"f_16cj_block70": {
		"title": "F-16V/CJ Wild Weasel : Suppression des Défenses Aériennes (SEAD/DEAD)",
		"domain": "AIR",
		"enemy_category": "Batteries de Missiles Sol-Air Mobiles (Buk-M3 / Tor-M2 / Pantsir)",
		"opposing_threat": "s_400_triumf",
		"friendly_partner": "f_35a_lightning",
		"move_act": "Vol TBA (Très Basse Altitude) à 60m sol à 540 kts sous la couverture radar, suivi d'une ressource verticale 'pop-up' brutale.",
		"fight": "Tir de 2 missiles anti-radar AGM-88E AARGM guidés sur les lobes latéraux du radar de tir ennemi.",
		"defend": "Système de guerre électronique ALQ-213, largage massif de paillettes chaffs et virage serré à 9G pour casser le verrouillage.",
		"special_trick": "AARGM Home-On-Jam : Si l'ennemi éteint son radar pour se protéger, le missile mémorise les coordonnées GPS exactes et active son autodirecteur millimétrique.",
		"friendly_integration": "Opère en binôme avec les F-35A : le F-35 localise, le F-16CJ tire les munitions lourdes anti-radar."
	},
	"rafale_f4_flight": {
		"title": "Dassault Rafale F4 : Pénétration Basse Altitude Omnirôle & Tir Meteor",
		"domain": "AIR",
		"enemy_category": "Chasseurs Polyvalents & Cibles Terrestres Fortifiées",
		"opposing_threat": "j_20_mighty_dragon",
		"friendly_partner": "f_35a_lightning",
		"move_act": "Suivi de terrain automatique numérique à 100m sol en conditions tout-temps. Super-croisière sans postcombustion à Mach 1.4.",
		"fight": "Missile air-air Meteor à statoréacteur (No-Escape Zone 3 fois supérieure aux missiles conventionnels) et missiles de croisière SCALP-EG.",
		"defend": "Système d'autoprotection SPECTRA créant des leurres électroniques virtuels (annulation active de signature).",
		"special_trick": "Statoréacteur Meteor : Régule sa poussée en vol pour conserver une énergie cinétique maximale lors du virage terminal à 60 km de distance.",
		"friendly_integration": "Liaison 16 et combat collaboratif F4 : Synchronisation des données capteurs optroniques OSF et radar RBE2-AESA."
	},
	"kf_21_boramae": {
		"title": "KAI KF-21 Boramae : Patrouille Frontière & Attaque Anti-Navire Côtière",
		"domain": "AIR",
		"enemy_category": "Flotilles de Débarquement & Chasseurs de Génération 4",
		"opposing_threat": "type_055_renhai",
		"friendly_partner": "f_35a_lightning",
		"move_act": "Profil de vol semi-furtif à Mach 1.8 avec soutes semi-encastrées sous le ventre.",
		"fight": "4 missiles Meteor en soute ventrale et 2 missiles anti-navires supersoniques air-sol.",
		"defend": "Contre-mesures intégrées DASS sud-coréennes et virages soutenus 7.5G.",
		"special_trick": "Frappe Côtière Rapide : Décolle sur alerte 5 minutes, tire ses missiles en semi-encastré et rompt le contact avant détection côtière.",
		"friendly_integration": "Interface directe avec les batteries Patriot PAC-3 et les destroyers KDX-III Aegis."
	},
	"hal_tejas_mk2": {
		"title": "HAL Tejas Mk2 : Interception Légère de Montagne & Dogfight Haute Altitude",
		"domain": "AIR",
		"enemy_category": "Chasseurs Moyens Transfrontaliers (JF-17 / J-10C)",
		"opposing_threat": "jf_17_block3_flight",
		"friendly_partner": "rafale_f4_flight",
		"move_act": "Agilité extrême en air raréfié au-dessus des crêtes à 5 000m grâce à son aile delta sans empennage et commandes électriques.",
		"fight": "Missiles BVR Astra Mk2 (portée 160 km) et missiles Python-5 à grand angle de tir au viseur de casque.",
		"defend": "Système de leurrage Mayawi et brouilleur de pod de guerre électronique.",
		"special_trick": "Virage Instantané Delta : Rayon de virage ultra-court au ras des parois rocheuses forçant l'assaillant à dépasser la cible.",
		"friendly_integration": "Relais de données tactiques avec les radars au sol des cols himalayens et avions de guet Netra."
	},
	"jf_17_block3_flight": {
		"title": "JF-17 Block III : Plateforme AESA Économique & Tir BVR PL-15",
		"domain": "AIR",
		"enemy_category": "Escadrons de Chasse Frontaliers Mixtes",
		"opposing_threat": "hal_tejas_mk2",
		"friendly_partner": "j_20_mighty_dragon",
		"move_act": "Montée rapide à 12 000m, radar AESA KLJ-7A en balayage large.",
		"fight": "Tir stand-off de 2 missiles PL-15 à guidage intermédiaire sécurisé.",
		"defend": "Distributeur automatique de paillettes et dégagement immédiat vers l'arrière.",
		"special_trick": "Rapport Coût/Létalité Massif : Déploie des missiles BVR de 5e génération sur un vecteur léger et économique produit en grand nombre.",
		"friendly_integration": "Datalink Link-17 avec stations terrestres et AWACS Saab Erieye."
	},

	# =========================================================================
	# 2. BOMBARDIERS STRATÉGIQUES & DRONES DE SOUTIEN AÉRIEN
	# =========================================================================
	"b_21_raider": {
		"title": "B-21 Raider : Pénétration Furtive Profonde & Frappe de Décapitation",
		"domain": "AIR",
		"enemy_category": "Bunkers de Commandement Profonds & Réseaux Radar Stratégiques",
		"opposing_threat": "s_400_triumf",
		"friendly_partner": "xq_58a_valkyrie",
		"move_act": "Vol subsonique à 14 500m sous signature radar quasiment nulle (équivalente à un insecte). Aucune émission RF.",
		"fight": "Largage de bombes pénétrantes anti-bunker GBU-57 MOP ou salves de 16 missiles de croisière furtifs AGM-158B.",
		"defend": "Absence totale de points chauds moteurs (tuyères dissimulées sur l'extrados). Déviation d'ondes millimétriques.",
		"special_trick": "Furtivité Globale Panoramique : Indétectable par radar sous n'importe quel angle (nez, flancs et tuyères arrières).",
		"friendly_integration": "Nœud de commandement aéroporté : Règle les flux de données entre les drones et le commandement stratégique."
	},
	"tu_22m3_backfire": {
		"title": "Tu-22M3M Backfire : Frappe Anti-Navire de Saturation à Longue Portée",
		"domain": "AIR",
		"enemy_category": "Groupes Aéro-Navals et Porte-Avions (CSG)",
		"opposing_threat": "ddg_51_arleigh_burke",
		"friendly_partner": "su_57_felon",
		"move_act": "Vol à géométrie variable (ailes en flèche maximale) à Mach 1.88 en haute altitude avant largage stand-off à 400 km.",
		"fight": "Salves de missiles anti-navires lourds Kh-32 à trajectoire semi-balistique atteignant Mach 4.6 en piqué terminal.",
		"defend": "Brouillage de puissance L-229 Ural et mitrailleur de queue assisté par radar.",
		"special_trick": "Frappe Hypersonique en Piqué Vertical : Les missiles montent à 40 000m avant de plonger à 80° sur le pont du porte-avions.",
		"friendly_integration": "Opère en régiments coordonnés de 12 appareils pour saturer simultanément les 96 silos d'un destroyer Aegis."
	},
	"e_3_sentry_awacs": {
		"title": "E-3G Sentry AWACS : Surveillance Aérienne de Théâtre & Contrôle d'Interception",
		"domain": "AIR",
		"enemy_category": "Raids Aériens Massifs & Missiles de Croisière Rasant",
		"opposing_threat": "j_20_mighty_dragon",
		"friendly_partner": "f_35a_lightning",
		"move_act": "Orbite en hippodrome à 10 200m, à 200 km en arrière de la ligne de front, vitesse de patrouille 360 kts.",
		"fight": "Aucun armement cinétique direct. Dirige les intercepteurs amis vers les vecteurs de tir optimaux.",
		"defend": "Escorte permanente de 2 à 4 chasseurs. Détecteurs d'alerte radar AN/ALR-56M et largage de leurres.",
		"special_trick": "Détection Look-Down Clutter-Free : Identifie les missiles de croisière furtifs volant à 30m au-dessus des vagues à 400 km de distance.",
		"friendly_integration": "Cœur C2 du Théâtre : Transmet automatiquement la situation aérienne (Air Picture) à toutes les unités alliées."
	},
	"kc_46_pegasus": {
		"title": "KC-46A Pegasus : Ravitaillement Stratégique & Boucle de Soutien Prolongé",
		"domain": "AIR",
		"enemy_category": "Usure Temporelle & Distance Opérationnelle Ennemie",
		"opposing_threat": "j_20_mighty_dragon",
		"friendly_partner": "f_35a_lightning",
		"move_act": "Vol de patrouille stable à 9 600m en zone sécurisée, déployant sa perche rigide 'fly-by-wire'.",
		"fight": "Fournit 96 000 kg de carburant en vol, doublant le temps sur zone (Playtime) des chasseurs de 45 min à 3 heures.",
		"defend": "Système de contre-mesures laser ALQ-212 (LAIRCM) neutralisant les missiles à guidage thermique.",
		"special_trick": "Relais de Réseau Aéroporté (ABN) : En plus du kérosène, agit comme passerelle de traduction entre la liaison MADL (F-35) et la Liaison 16.",
		"friendly_integration": "Point de ralliement vital des patrouilles aériennes de combat (CAP) avant réengagement."
	},

	# =========================================================================
	# 3. DRONES DE COMBAT COLLABORATIF (LOYAL WINGMEN) & UCAV
	# =========================================================================
	"xq_58a_valkyrie": {
		"title": "XQ-58A Valkyrie : Ailier Furtif Sacrifiable & Appât Électronique",
		"domain": "AIR",
		"enemy_category": "Batteries SAM de Haute Intensité & Chasseurs Ennemis",
		"opposing_threat": "s_400_triumf",
		"friendly_partner": "f_35a_lightning",
		"move_act": "Vol d'accompagnement à Mach 0.85 à 9 500m, précédant l'avion piloté de 30 km.",
		"fight": "Emport interne de 2 bombes GBU-39 SDB ou 2 missiles AIM-120D, tirés sous autorisation de l'avion maître.",
		"defend": "Signature radar réduite. Accepte le sacrifice pour préserver la vie du pilote de l'appareil leader.",
		"special_trick": "Appât Radar Actif (Bait & Hook) : Allume son radar avec une modulation trompeuse pour attirer les tirs de missiles ennemis, révélant la position exacte de la batterie.",
		"friendly_integration": "Contrôlé par IA autonome avec garde-fous éthiques, obéissant aux ordres gestuels et vocaux du F-35A leader."
	},
	"mq_28_ghost_bat": {
		"title": "MQ-28 Ghost Bat : Bouclier Sensoriel IA & Brouillage Déporté",
		"domain": "AIR",
		"enemy_category": "Intercepteurs Ennemis Furtifs & Radars Côtiers",
		"opposing_threat": "su_57_felon",
		"friendly_partner": "f_35a_lightning",
		"move_act": "Vol autonome en formation serrée à 10 500m, nez modulaire interchangeable en moins de 2 heures.",
		"fight": "Nez capteur optronique et désignation laser longue portée, emport d'armes d'interception.",
		"defend": "Brouillage ECM d'autoprotection et manœuvres d'évitement calculées par modèle de deep learning local.",
		"special_trick": "Nez Capteur Déporté : Se place en avant-garde pour détecter optroniquement les jets ennemis sans risquer l'appareil piloté.",
		"friendly_integration": "Intégration native dans le Combat System australien et américain via réseau sans fil durci."
	},
	"s_70_okhotnik": {
		"title": "Sukhoi S-70 Okhotnik-B : UCAV Furtif Lourd de Pénétration",
		"domain": "AIR",
		"enemy_category": "Radars de Détection Lointaine & Lignes de Défense Durcies",
		"opposing_threat": "mim_104f_patriot",
		"friendly_partner": "su_57_felon",
		"move_act": "Aile volante furtive de 20 tonnes, vol subsonique élevé à 12 000m.",
		"fight": "Emporte jusqu'à 6 tonnes d'armement lourd en soutes internes (missiles Kh-59MK2, bombes guidées).",
		"defend": "Forme d'aile volante réduisant l'écho radar frontal et tuyère protégée.",
		"special_trick": "Brise-Ligne Furtif : Pénètre les défenses blindées pour détruire les centres C2 avant le passage des chasseurs pilotés.",
		"friendly_integration": "Opère sous le contrôle direct du cockpit biplace du Su-57 ou de manière autonome préprogrammée."
	},
	"bayraktar_kizilelma": {
		"title": "Bayraktar Kizilelma : Chasseur Furtif Sans Pilote Supersonique",
		"domain": "AIR",
		"enemy_category": "Chasseurs Aériens & Drones Moyens Adverses",
		"opposing_threat": "f_16cj_block70",
		"friendly_partner": "bayraktar_akinci_ucav",
		"move_act": "Vitesse transsonique/supersonique avec plan canard, haute manœuvrabilité et plafond 14 000m.",
		"fight": "Radar AESA indigène Murad, missiles air-air Bozdogan et Gokdogan tirés en mode autonome.",
		"defend": "Basse observabilité radar, capteurs passifs ESM et capacité d'atterrissage sur porte-aéronefs à piste courte.",
		"special_trick": "Déploiement Naval Court : Capable de décoller et d'apponter sans brin d'arrêt sur le TCG Anadolu.",
		"friendly_integration": "Travaille en essaim avec les drones MALE Akinci pour une couverture aéro-maritime totale."
	},
	"bayraktar_akinci_ucav": {
		"title": "Bayraktar Akinci : Sentinelle MALE d'Endurance & Frappe Précise",
		"domain": "AIR",
		"enemy_category": "Colonnes Blindées & Positions d'Artillerie Terrestre",
		"opposing_threat": "t_90m_platoon",
		"friendly_partner": "bayraktar_kizilelma",
		"move_act": "Vol d'endurance de 24 heures à 7 500m d'altitude, propulsé par deux turbopropulseurs de 750 ch.",
		"fight": "Emporte 1 500 kg de munitions sous voilure : missiles de croisière SOM-A (250 km) et bombes MAM-T.",
		"defend": "Vol hors de portée des canons anti-aériens et MANPADS, alerte radar embarquée.",
		"special_trick": "Frappe Stand-Off Haute Altitude : Tire ses missiles de croisière à plus de 200 km de distance sans jamais entrer dans la bulle SAM ennemie.",
		"friendly_integration": "Assure la désignation d'objectifs pour les salves d'artillerie côtière et roquettes terrestres."
	},
	"palianytsia_drone_uk": {
		"title": "Palianytsia : Drone-Fusée à Réaction & Frappe dans la Profondeur",
		"domain": "AIR",
		"enemy_category": "Bases Aériennes Stratégiques & Dépôts de Munitions Profonds",
		"opposing_threat": "s_400_triumf",
		"friendly_partner": "fpv_fiber_swarm",
		"move_act": "Propulsé par un turboréacteur compact, croisière rapide à 2 400m à plus de 500 km/h.",
		"fight": "Charge militaire de 100 kg explosive à effet de souffle détonant sur les hangars d'aviation.",
		"defend": "Vol rasant de nuit suivant les vallées et cours d'eau pour échapper aux radars de veille.",
		"special_trick": "Vitesse d'Impact Réacteur : Rend toute interception par mitrailleuses de toit impossible en phase d'attaque terminale.",
		"friendly_integration": "Lancé en vagues coordonnées pour saturer les défenses avant le passage des missiles de croisière."
	},

	# =========================================================================
	# 4. ESSAIMS DE DRONES & MUNITIONS TÉLÉ-OPÉRÉES (LOITERING / FPV)
	# =========================================================================
	"fpv_fiber_swarm": {
		"title": "Essaim FPV Fibre Optique : Chasseurs Aveugles & Insensibles au Brouillage",
		"domain": "LAND",
		"enemy_category": "Chars de Combat Lourds & Postes de Tir Blindés",
		"opposing_threat": "t_90m_platoon",
		"friendly_partner": "vision_60_q_ugv",
		"move_act": "Vol au ras de la cime des arbres à 45 m/s, déployant une bobine de micro-fibre de verre de 20 km.",
		"fight": "Charge creuse tandem PG-7VL perforant 600mm de blindage homogène sur le toit de tourelle vulnérable.",
		"defend": "Taille minuscule rendant le tir d'arme légère inefficace.",
		"special_trick": "Immunité Électronique Totale : Guidé par fil optique physique — totalement invulnérable au brouillage radio (Krasukha, dômes EW).",
		"friendly_integration": "Guidé vers l'objectif par les chiens robots en reconnaissance avancée."
	},
	"switchblade_600_team": {
		"title": "Switchblade 600 : Munition Rôdeuse Anti-Char Pliable & Frappe Top-Attack",
		"domain": "LAND",
		"enemy_category": "Blindés d'État-Major & Véhicules Radar de Haute Valeur",
		"opposing_threat": "krasukha_4_ew",
		"friendly_partner": "m2a4_mech_company",
		"move_act": "Décollage en tube pneumatique, déploiement d'ailes et patrouille silencieuse à 850m pendant 40 minutes.",
		"fight": "Plongeon d'attaque vertical à 185 km/h avec charge perforante Javelin contre la toiture blindée.",
		"defend": "Silencieux et indétectable visuellement à plus de 200m d'altitude.",
		"special_trick": "Capacité 'Wave-Off' : Peut annuler son attaque à 2 secondes de l'impact si des civils sont détectés et reprendre sa patrouille.",
		"friendly_integration": "Déployé par une équipe de 2 soldats et relayé sur la tablette tactique du commandant de compagnie."
	},
	"lancet_3_team": {
		"title": "ZALA Lancet-3 : Munition Rôdeuse à Ailes en Croix & Suivi Optique IA",
		"domain": "LAND",
		"enemy_category": "Canons d'Artillerie Automoteurs & Batteries Sol-Air (Caesar / M109)",
		"opposing_threat": "bohdana_2s22_artillery",
		"friendly_partner": "spetsnaz_sniper_commando",
		"move_act": "Ailes en double X conférant une très grande stabilité en piqué à 300 km/h.",
		"fight": "Charge creuse de 5 kg à fragmentation détonant par détection laser de proximité.",
		"defend": "Signature thermique quasi-nulle (moteur électrique).",
		"special_trick": "Verrouillage IA Autonome en Phase Finale : Conserve la cible même en cas de coupure du signal vidéo de l'opérateur.",
		"friendly_integration": "Opère sous la désignation d'un drone éclaireur ZALA 421-16E en haute altitude."
	},
	"shahed_136_launcher": {
		"title": "Shahed-136 / Geran-2 : Camion de Saturation OWA à Longue Portée",
		"domain": "LAND",
		"enemy_category": "Infrastructures Énergétiques, Dépôts & Réseaux Radar de Zone",
		"opposing_threat": "skynex_ahead_battery",
		"friendly_partner": "krasukha_4_ew",
		"move_act": "Vol de croisière économique à 180 km/h à 60m sol sur 1 500 km propulsé par moteur MD-550.",
		"fight": "Charge explosive de 50 kg détonant à l'impact avec coordonnées programmées.",
		"defend": "Structure en fibre de verre absorbant les ondes radar et vol par vagues nocturnes dispersées.",
		"special_trick": "Saturation Économique Délibérée : Coûte 20 000 $ pour forcer l'ennemi à gaspiller des missiles d'interception Patriot à 3 000 000 $.",
		"friendly_integration": "Lancé en essaim de 5 depuis un conteneur camouflé sur châssis civil."
	},
	"iai_harop_launcher": {
		"title": "IAI Harop : Rôdeur Chasseur de Radars & Furtif Anti-Rayonnement",
		"domain": "LAND",
		"enemy_category": "Radars de Conduite de Tir Sol-Air Ennemis",
		"opposing_threat": "s_400_triumf",
		"friendly_partner": "tier1_sniper_recon_team",
		"move_act": "Vol d'attente de 9 heures au-dessus du secteur disputé, prêt à fondre sur tout émetteur qui s'allume.",
		"fight": "Plongeon kamikaze guidé directement sur le faisceau électromagnétique du radar ennemi.",
		"defend": "Structure composite furtive invisible aux radars tant qu'il plane en silence.",
		"special_trick": "Anti-Radar Pur : Dès que le radar ennemi s'active pour chercher une cible, le Harop plonge droit dans l'antenne.",
		"friendly_integration": "Travaille de concert avec les forces spéciales JTAC infiltrées derrière les lignes."
	},

	# =========================================================================
	# 5. CHIENS ROBOTS QUADRUPÈDES & UGV TERRESTRES
	# =========================================================================
	"vision_60_q_ugv": {
		"title": "Ghost Robotics Vision 60 : Chien Robot Éclaireur de Falaise & JTAC",
		"domain": "LAND",
		"enemy_category": "Blindés Lourds en Terrain Accidenté & Tunnels de Montagne",
		"opposing_threat": "t_90m_platoon",
		"friendly_partner": "tier1_sniper_recon_team",
		"move_act": "Quadrupède à couple variable escaladant des pentes rocailleuses abruptes (>35°), traversant l'eau et les gravats urbains.",
		"fight": "Désignation laser JTAC d'objectifs pour obus d'artillerie guidés Excalibur ou tirs FPV.",
		"defend": "Silencieux, silhouette ultra-basse (45cm), insensible aux mines anti-chars grâce à son poids plume (51 kg).",
		"special_trick": "Franchissement de Pentes Abruptes : Contourne les blindés ennemis en gravissant des parois rocheuses impraticables pour tout véhicule à roues ou chenilles.",
		"friendly_integration": "S'intègre dans le sac à dos du sniper JTAC et transmet une cartographie 3D LiDAR en temps réel à l'équipe."
	},
	"unitree_b2w_armed": {
		"title": "Unitree B2-W Armé : Quadrupède à Roues-Pattes d'Assaut Urbain",
		"domain": "LAND",
		"enemy_category": "Nids de Mitrailleuses & Tranchées d'Infanterie Fortifiées",
		"opposing_threat": "spetsnaz_sniper_commando",
		"friendly_partner": "m2a4_mech_company",
		"move_act": "Roues motorisées sur les pattes permettant 25 km/h sur bitume et saut d'obstacles de 80cm en mode marcheur.",
		"fight": "Tourelle téléopérée armée d'un fusil d'assaut 5.8mm avec visée optronique thermique stabilisée.",
		"defend": "Blindage pare-éclats composite léger et profil fuyant.",
		"special_trick": "Sprint Urbain Hybride : Passe instantanément du roulage haute vitesse à l'escalade d'escaliers pour nettoyer un bunker.",
		"friendly_integration": "Fer de lance d'assaut en première ligne, protégeant les fantassins humains derrière son avancée."
	},
	"milrem_themis_ugv": {
		"title": "Milrem THeMIS : UGV Chenillé Modulaire & Poste de Tir Anti-Char Déporté",
		"domain": "LAND",
		"enemy_category": "Formations Blindées Mixtes & Évacuation Médicale sous le Feu",
		"opposing_threat": "t_90m_platoon",
		"friendly_partner": "m1a2_sepv3_platoon",
		"move_act": "Chenilles tout-terrain franchissant tranchées et bourbiers avec motorisation hybride diesel-électrique silencieuse.",
		"fight": "Tourelle télé-opérée avec 2 missiles anti-chars Javelin et mitrailleuse lourde coaxiale .50 BMG.",
		"defend": "Générateur fumigène thermique et silhouette basse masquée par le relief de terrain.",
		"special_trick": "Tir Déporté Sans Risque Humain : L'opérateur reste terré dans un trou de combat à 800m pendant que le THeMIS engage le char adverse.",
		"friendly_integration": "Assure aussi le transport de 750 kg de munitions ou l'évacuation de blessés couchés sous blindage."
	},
	"uran_9_ugv": {
		"title": "Uran-9 : Char Robotique Lourd & Appui Feu Urbain Chenillé",
		"domain": "LAND",
		"enemy_category": "Bunkers Fortifiés & Blindés Moyens d'Infanterie",
		"opposing_threat": "m2a4_mech_company",
		"friendly_partner": "t_90m_platoon",
		"move_act": "Chenilles blindées de 12 tonnes progressant dans les rues décombres à 35 km/h.",
		"fight": "Canon automatique de 30mm 2A72, 4 missiles anti-chars 9M120 Ataka et 6 lance-roquettes thermobariques Shmel.",
		"defend": "Blindage acier protégeant contre le calibre 12.7mm et système de détection laser de visée ennemie.",
		"special_trick": "Salve Thermobarique Intégrée : Balaye un pâté de maisons fortifié en saturant l'air d'explosif volumétrique avant assaut.",
		"friendly_integration": "Opère par liaison radio cryptée sécurisée sous l'égide d'un char de commandement T-90M."
	},

	# =========================================================================
	# 6. BLINDÉS LOURDS & CAVALERIE MÉCANISÉE
	# =========================================================================
	"m1a2_sepv3_platoon": {
		"title": "M1A2 SEPv3 Abrams : Peloton Blindé de Rupture & Protection Trophy APS",
		"domain": "LAND",
		"enemy_category": "Chars de Combat Principaux & Missiles ATGM Sol-Sol",
		"opposing_threat": "t_90m_platoon",
		"friendly_partner": "m2a4_mech_company",
		"move_act": "Poids de combat 73 tonnes, propulsion par turbine à gaz de 1 500 ch franchissant les obstacles à 67 km/h.",
		"fight": "Canon à âme lisse 120mm M256 tirant l'obus perforant à uranium appauvri M829A4 détruisant tout blindage connu à 3 500m.",
		"defend": "Système de protection active Trophy APS interceptant les roquettes et missiles anti-chars à 15m de la tourelle.",
		"special_trick": "Interception Hardkill Trophy : Détruit les missiles ATGM arrivant à 300 m/s avant qu'ils ne touchent le blindage principal.",
		"friendly_integration": "Système d'information FBCB2 / JBC-P : Partage instantané des contacts ennemis avec les véhicules Bradley et chiens robots."
	},
	"t_90m_platoon": {
		"title": "T-90M Proryv-3 : Rupture Blindée & Blindage Réactif Relikt",
		"domain": "LAND",
		"enemy_category": "Blindés Lourds Adverses & Postes Anti-Char Fortifiés",
		"opposing_threat": "m1a2_sepv3_platoon",
		"friendly_partner": "uran_9_ugv",
		"move_act": "Silhouette basse de 2.22m difficile à viser, franchissement rapide en tout-terrain avec moteur diesel 1 130 ch.",
		"fight": "Canon 125mm 2A46M-5 tirant obus APFSDS et missiles guidés 9M119M Refleks à travers le canon à 5 km.",
		"defend": "Blindage réactif explosif Relikt couvrant le glacis et les flancs, système de brouillage optique Shtora.",
		"special_trick": "Tir Missile Canon Longue Portée : Tire un missile Refleks téléguidé par faisceau laser sur un blindé avant qu'il ne soit à portée d'obus standard.",
		"friendly_integration": "Connecté au système de gestion tactique Sozvezdie pour coordination interarmes."
	},
	"leopard_2a8_platoon": {
		"title": "Leopard 2A8 : Fer de Lance Blindé Européen & Conduite de Tir Thermique 3e Gén",
		"domain": "LAND",
		"enemy_category": "Formations Blindées Mixtes & Vagues d'Assaut Terrestre",
		"opposing_threat": "t_90m_platoon",
		"friendly_partner": "m2a4_mech_company",
		"move_act": "Châssis agile avec suspension à barres de torsion renforcées, vitesse de recul de 31 km/h pour tir en repli.",
		"fight": "Canon Rheinmetall 120mm L/55A1 développant une pression de chambre phénoménale et munition programmable DM11.",
		"defend": "Système Trophy intégré d'usine et blindage composite multicouche tungsten-céramique.",
		"special_trick": "Munition DM11 Programmable : L'obus explose avec précision mathématique au-dessus d'une tranchée pour neutraliser l'infanterie terrée.",
		"friendly_integration": "Liaison de données OTAN standardisée avec l'artillerie et les drones d'observation."
	},
	"k2_black_panther": {
		"title": "K2 Black Panther : Char de Montagne à Suspension Oléopneumatique",
		"domain": "LAND",
		"enemy_category": "Blindés en Colline & Positions Dominantes sur Crête",
		"opposing_threat": "t_90m_platoon",
		"friendly_partner": "vision_60_q_ugv",
		"move_act": "Suspension oléopneumatique 'In-arm' s'abaissant, se levant, s'inclinant vers l'avant ou vers l'arrière.",
		"fight": "Canon 120mm L/55 avec radar millimétrique de conduite de tir et obus intelligent KSTAM tiré en cloche.",
		"defend": "Radar de détection d'obus et grenade fumigène multi-spectrale.",
		"special_trick": "Posture Inclinée (Kneeling/Tilting) : S'incline vers l'arrière pour pointer son canon vers des hélicoptères ou positions situées sur des falaises abruptes.",
		"friendly_integration": "Réseau tactique C4I coréen avec transfert d'objectifs immédiat aux pièces K9 Thunder."
	},
	"m2a4_mech_company": {
		"title": "M2A4 Bradley : Cavalerie Mécanisée & Débarquement de Chiens Robots",
		"domain": "LAND",
		"enemy_category": "Infanterie Ennemie Fortifiée & Blindés Légers de Reconnaissance",
		"opposing_threat": "btr_4_bucephalus_co",
		"friendly_partner": "m1a2_sepv3_platoon",
		"move_act": "Chenillé rapide de 36 tonnes transportant 6 fantassins d'assaut et 2 chiens robots Vision 60 en soute.",
		"fight": "Canon-mitrailleur 25mm M242 Bushmaster tirant 200 cps/min et tourelle double missile antichar TOW-2B Aero.",
		"defend": "Blindage réactif appliqué et viseur thermique de chef indépendant CIV.",
		"special_trick": "TOW-2B Top-Attack : Le missile passe au-dessus du char ennemi et fait exploser deux charges formées vers le bas à travers le toit mince.",
		"friendly_integration": "Coopère intimement avec les chars Abrams : le Bradley nettoie l'infanterie anti-char, l'Abrams détruit les gros calibres."
	},
	"btr_4_bucephalus_co": {
		"title": "BTR-4E Bucephalus : Infanterie Mécanisée Roues 8x8 & Équipes FPV",
		"domain": "LAND",
		"enemy_category": "Infiltrations d'Infanterie Rapides & Colonnes de Ravitaillement",
		"opposing_threat": "m2a4_mech_company",
		"friendly_partner": "t_84_oplot_platoon",
		"move_act": "Mobilité roues 8x8 à 110 km/h sur route et capacité amphibie à travers les fleuves.",
		"fight": "Module de combat Parus : canon 30mm ZTM-1, lance-grenades 30mm, 2 missiles antichars Barrier et mitrailleuse 7.62mm.",
		"defend": "Grilles anti-RPG protégeant la caisse contre les charges creuses simples.",
		"special_trick": "Embarquement Immédiat d'Équipes FPV : Sert de relais radio et d'atelier de recharge pour escouades de drones légers.",
		"friendly_integration": "Dépêche des équipes de tireurs d'élite et de drones pour fixer l'ennemi avant tir d'artillerie."
	},

	# =========================================================================
	# 7. FORCES SPÉCIALES, SNIPERS JTAC & INFANTERIE D'ÉLITE
	# =========================================================================
	"tier1_sniper_recon_team": {
		"title": "Sniper Tier-1 & JTAC Laser : Élimination de Précision & Frappe Guidée",
		"domain": "LAND",
		"enemy_category": "Officiers de Commandement, Postes Radar & Tireurs Isolés",
		"opposing_threat": "spetsnaz_sniper_commando",
		"friendly_partner": "vision_60_q_ugv",
		"move_act": "Infiltration pédestre silencieuse de nuit avec tenues ghillie multi-spectrales invisibles aux caméras thermiques.",
		"fight": "Fusil anti-matériel Barrett M107 calibre .50 BMG (portée létale 2 000m) et désignateur laser SOFLAM.",
		"defend": "Dissimulation totale dans les crevasses et utilisation de silencieux suppresseurs soniques.",
		"special_trick": "Guidage Laser JTAC Buddy Lasing : Illumine un bunker avec son faisceau laser invisible pour qu'une bombe larguée par un F-35A à 15 km vienne frapper la fenêtre exacte.",
		"friendly_integration": "Opère avec un chien robot Vision 60 qui porte les munitions lourdes et assure la garde arrière à 360°."
	},
	"navy_seal_commando_squad": {
		"title": "Commandos SEAL / SAS : Sabotage Maritime & Infiltration Côtière",
		"domain": "LAND",
		"enemy_category": "Stations Radar Côtières & Câbles Sous-Marins de Communication",
		"opposing_threat": "spetsnaz_sniper_commando",
		"friendly_partner": "orca_xluuv",
		"move_act": "Insertion sous-marine discrète depuis un sous-marin via propulseurs de plongée DPV à 15m sous la surface.",
		"fight": "Armes silencieuses de combat rapproché, charges de démolition thermite et explosifs C4.",
		"defend": "Respirateurs à circuit fermé ne produisant aucune bulle en surface.",
		"special_trick": "Sabotage Furtif de Fond de Mer : Pose des charges sur les points d'atterrissement des câbles sous-marins ennemis pour couper internet et le commandement adverse.",
		"friendly_integration": "Récupéré par un sous-marin autonome Orca XLUUV sans laisser de trace."
	},
	"spetsnaz_sniper_commando": {
		"title": "Spetsnaz Recon & Sabotage : Neutralisation de Nœuds Logistiques Arrière",
		"domain": "LAND",
		"enemy_category": "Dépôts de Munitions Alliés, Ponts & Convois de Ravitaillement",
		"opposing_threat": "tier1_sniper_recon_team",
		"friendly_partner": "t_90m_platoon",
		"move_act": "Progression en milieu forestier dense, contournement complet des axes routiers surveillés.",
		"fight": "Fusil de précision VSS Vintorez 9x39mm subsonique et mines intelligentes à détection sismique.",
		"defend": "Combinaisons camouflées anti-infrarouges et dispersion immédiate en binômes.",
		"special_trick": "Minage Sismique d'Axe Stratégique : Enterre des mines intelligentes qui ne détonent que lorsqu'un convoi de carburant passe (filtrage acoustique).",
		"friendly_integration": "Renseigne le quartier général sur les coordonnées exactes des batteries Patriot à frapper par missile Iskander."
	},

	# =========================================================================
	# 8. ARMES À ÉNERGIE DIRIGÉE & DÉFENSE ANTI-AÉRIENNE RAPPROCHÉE (C-UAS)
	# =========================================================================
	"epirus_leonidas_hpm": {
		"title": "Epirus Leonidas HPM : Cône Micro-Ondes de Neutralisation d'Essaims",
		"domain": "LAND",
		"enemy_category": "Essaims de Drones Saturants (Shahed-136 / FPV Kamikazes)",
		"opposing_threat": "shahed_136_launcher",
		"friendly_partner": "skynex_ahead_battery",
		"move_act": "Monté sur châssis blindé Stryker 8x8 ou conteneur tactique déployable en 3 minutes.",
		"fight": "Émet un faisceau d'ondes micro-ondes haute puissance (HPM) à état solide créant un cône de 30° d'interception.",
		"defend": "Blindage de caisse Stryker et système d'extinction d'arc électrique.",
		"special_trick": "Destruction Instantanée d'Essaim (Zero Flight Time) : Foudroie simultanément les composants électroniques de 10 à 30 drones d'un coup à la vitesse de la lumière (sans dépense de munitions physiques).",
		"friendly_integration": "Protège le dôme d'une batterie Patriot PAC-3 contre les attaques de saturation à bas coût."
	},
	"iron_beam_helws": {
		"title": "Iron Beam 100kW : Laser à Fibre Haute Énergie & Tir Silencieux à Vitesse Lumière",
		"domain": "LAND",
		"enemy_category": "Roquettes d'Artillerie, Obus de Mortier & Petits Drones",
		"opposing_threat": "kn_25_mlrs_battery",
		"friendly_partner": "mim_104f_patriot",
		"move_act": "Station fixe ou remorquable avec système de refroidissement liquide industriel haute capacité.",
		"fight": "Faisceau laser à fibre de 100 kW concentré sur un point de 5cm d'une cible en vol à 7 km.",
		"defend": "Chauffage thermique structural faisant exploser l'ogive de la roquette en plein vol en 3 secondes.",
		"special_trick": "Coût de Tir à 3.50 $ : Détruit les projectiles balistiques pour le coût électrique d'une cafetière, sans stock de missiles limité.",
		"friendly_integration": "Prend en charge les cibles bon marché pour préserver les intercepteurs cinétiques coûteux du Dôme de Fer."
	},
	"skynex_ahead_battery": {
		"title": "Rheinmetall Skynex 35mm : Rideau de Tungstène AHEAD Anti-Drones",
		"domain": "LAND",
		"enemy_category": "Missiles de Croisière Rasant & Drones Rôdeurs en Piqué",
		"opposing_threat": "shahed_136_launcher",
		"friendly_partner": "epirus_leonidas_hpm",
		"move_act": "Tourelle automatisée Oerlikon revolver 35mm déployable sur points hauts avec radar de suivi bande X.",
		"fight": "Cadence de 1 000 coups/minute tirant des obus programmables AHEAD qui expulsent 152 sous-projectiles de tungstène par coup.",
		"defend": "Tourelle sans personnel télé-opérée sous caisson blindé.",
		"special_trick": "Programmation inductive à la bouche : La vitesse exacte du projectile est mesurée en sortie de canon et le retardateur d'explosion est programmé en 1 microseconde pour créer un nuage d'impact infranchissable.",
		"friendly_integration": "Défense terminale ultime des centrales électriques et centres C2."
	},
	"krasukha_4_ew": {
		"title": "Krasukha-4 : Brouilleur Radar Stratégique de Théâtre & Aveuglement Satellite",
		"domain": "LAND",
		"enemy_category": "Radars AWACS, Satellites SAR et Autodirecteurs de Missiles",
		"opposing_threat": "e_3_sentry_awacs",
		"friendly_partner": "s_400_triumf",
		"move_act": "Deux camions KamAZ tout-terrain déployant des paraboles émettrices haute puissance orientables.",
		"fight": "Brouillage de saturation et tromperie DRFM sur les radars en bande X et Ku jusqu'à 300 km de distance.",
		"defend": "Blindage cabine contre les éclats d'obus et déploiement sous filet de camouflage thermique.",
		"special_trick": "Aveuglement de Radar Orbital : Rend les satellites espions SAR incapables de photographier le secteur à travers les nuages.",
		"friendly_integration": "Crée une ombrelle de silence pour masquer les déplacements de convois blindés et lanceurs de missiles."
	},

	# =========================================================================
	# 9. BATTERIES STRATÉGIQUES SOL-AIR ET MISSILES BALISTIQUES
	# =========================================================================
	"mim_104f_patriot": {
		"title": "MIM-104F Patriot PAC-3 MSE : Interception Cinétique Hit-To-Kill",
		"domain": "LAND",
		"enemy_category": "Missiles Balistiques Tactiques & Missiles Hypersoniques",
		"opposing_threat": "kn_25_mlrs_battery",
		"friendly_partner": "iron_beam_helws",
		"move_act": "Batterie de 6 à 8 lanceurs montés sur semi-remorques avec radar multifonction AN/MPQ-65.",
		"fight": "Missile PAC-3 MSE avec micro-propulseurs latéraux ACM percutant la tête du missile ennemi à Mach 4.1.",
		"defend": "Interception cinétique directe détruisant l'ogive ennemie (Hit-to-Kill) sans dépendre de l'onde de choc.",
		"special_trick": "Hit-to-Kill Absolu : Percute physiquement la charge nucléaire ou chimique adverse pour l'annihiler dans la stratosphère.",
		"friendly_integration": "Intégré dans le système IBCS américain unifiant les radars côtiers et les destroyers Aegis."
	},
	"s_400_triumf": {
		"title": "S-400 Triumf : Dôme Anti-Aérien Stratégique Multi-Portée",
		"domain": "LAND",
		"enemy_category": "Chasseurs Supérieurs, Bombardiers et Missiles Aérobies",
		"opposing_threat": "f_35a_lightning",
		"friendly_partner": "krasukha_4_ew",
		"move_act": "Châssis 8x8 BAZ-6402 se déployant en batterie de combat en moins de 5 minutes.",
		"fight": "Mixe 4 types de missiles : 40N6E très longue portée (400 km), 48N6 (250 km) et 9M96E2 agiles moyenne portée.",
		"defend": "Défendu de près par des véhicules Pantsir-S1 protégeant le radar Big Bird contre les drones rasants.",
		"special_trick": "Trajectoire Stratosphérique 40N6E : Le missile monte à 35 km d'altitude puis redescend avec son propre autodirecteur radar actif sur des cibles masquées par la rotondité terrestre.",
		"friendly_integration": "Point focal de la bulle d'interdiction A2/AD (Anti-Access / Area Denial)."
	},
	"dark_eagle_battery": {
		"title": "LRHW Dark Eagle : Batterie Hypersonique à Boost-Glide Mach 17",
		"domain": "LAND",
		"enemy_category": "Postes de Commandement Fortifiés & Quartiers Généraux de Théâtre",
		"opposing_threat": "s_400_triumf",
		"friendly_partner": "ddg_51_arleigh_burke",
		"move_act": "Lanceurs mobiles tractés déployant le corps hypersonique C-HGB monté sur booster balistique.",
		"fight": "Atteint Mach 17 (plus de 5.8 km/s) dans la haute atmosphère, planant à 60 km d'altitude sur 2 800 km.",
		"defend": "Vitesse extrême et manœuvres de vol plané rendant toute interception impossible par les SAM conventionnels.",
		"special_trick": "Frappe en Temps Critique (Prompt Global Strike) : Touche une cible stratégique à 2 500 km de distance en moins de 12 minutes.",
		"friendly_integration": "Reçoit les coordonnées d'objectifs validées par les constellations de satellites LEO."
	},
	"brahmos_coastal_battery": {
		"title": "BrahMos PJ-10 : Batterie Côtière Supersonique Mach 3.0",
		"domain": "LAND",
		"enemy_category": "Navires de Guerre Principaux & Frégates d'Escorte",
		"opposing_threat": "type_055_renhai",
		"friendly_partner": "zorawar_mountain_tank",
		"move_act": "Tracteurs-érecteurs 12x12 camouflés sur falaises côtières ou cols de montagne.",
		"fight": "Missile à statoréacteur croisant à Mach 3.0 (1 km/s) avec charge explosive perforante de 300 kg.",
		"defend": "Vol rasant au-dessus des vagues à 10m d'altitude suivi d'une manœuvre en S évasive finale.",
		"special_trick": "Énergie Cinétique Monstrueuse : Même sans charge explosive, la masse de 3 tonnes arrivant à Mach 3 brise en deux la coque d'une frégate.",
		"friendly_integration": "Connecté aux stations de détection radar côtières et avions de patrouille maritime P-8I."
	},
	"neptune_rk360mc_battery": {
		"title": "RK-360MC Neptune : Missiles Anti-Navires Côtiers à Guidage Rasant",
		"domain": "LAND",
		"enemy_category": "Croiseurs Américains / Russes & Bâtiments de Débarquement",
		"opposing_threat": "admiral_gorshkov_frigate",
		"friendly_partner": "palianytsia_drone_uk",
		"move_act": "Camions tout-terrain Tatra 8x8 dispersés dans des bois à 25 km du rivage pour éviter les frappes de riposte.",
		"fight": "Salves de 4 missiles R-360 volant à 5m de la surface de l'eau à 900 km/h sur 300 km.",
		"defend": "Silence radar total des camions de lancement grâce au radar passif Mineral-U.",
		"special_trick": "Attaque à Ras des Vagues : Se dissimule dans le bruit de fond des vagues pour échapper aux radars des systèmes de défense de point CIWS.",
		"friendly_integration": "Désignation initiale fournie par drone Bayraktar TB2 détournant l'attention du croiseur."
	},
	"bohdana_2s22_artillery": {
		"title": "2S22 Bohdana : Canon Automoteur 155mm Mobile 'Shoot-and-Scoot'",
		"domain": "LAND",
		"enemy_category": "Batteries d'Artillerie Opposées & Concentrations d'Infanterie",
		"opposing_threat": "t_90m_platoon",
		"friendly_partner": "btr_4_bucephalus_co",
		"move_act": "Châssis à roues 8x8 capable de quitter sa position en moins de 60 secondes après le tir.",
		"fight": "Obus 155mm standard OTAN et munitions de précision à portée étendue (42 km avec obus à culot creux).",
		"defend": "Cabine blindée résistant aux tirs de 7.62mm et éclats d'obus de contre-batterie.",
		"special_trick": "Tir et Disparition (Shoot-and-Scoot) : Tire 3 obus en 30 secondes et roule déjà à 70 km/h quand les obus touchent l'ennemi.",
		"friendly_integration": "Synchronisé avec le logiciel de cartographie d'artillerie Kropyva et données de drones Mavic/Leleka."
	},

	# =========================================================================
	# 10. GUERRE SOUS-MARINE & DRONES NAVALS (USV / UUV)
	# =========================================================================
	"ssn_688i_los_angeles": {
		"title": "USS Cheyenne SSN-688(I) : Chasseur Sous-Marin Discret & Torpilles Filoguidées",
		"domain": "SEA",
		"enemy_category": "Sous-Marins Nucléaires Ennemis & Frégates Anti-Sous-Marines",
		"opposing_threat": "type_093b_shang_ssn",
		"friendly_partner": "ddg_51_arleigh_burke",
		"move_act": "Navigation silencieuse à 5 kts sous la couche thermique océanique (thermocline), hélice sabre à 7 pales.",
		"fight": "4 tubes lance-torpilles 533mm tirant la torpille lourde Mk 48 ADCAP filoguidée et 12 silos verticaux VLS Tomahawk.",
		"defend": "Immersion jusqu'à 450m, lanceurs de leurres acoustiques ADC Mk 2 et revêtement anéchoïque absorbant les sonars actifs.",
		"special_trick": "Affût Sous la Thermocline : Utilise la réfraction thermique de l'eau comme un miroir acoustique rendant le sous-marin invisible aux sonars de surface.",
		"friendly_integration": "Liaison satellite ELF/VLF pour réception des ordres de frappe stratégique et coordination avec le réseau SOSUS."
	},
	"type_093b_shang_ssn": {
		"title": "Type 093B Shang-III : Sous-Marin Nucléaire d'Attaque & Tir VLS YJ-18",
		"domain": "SEA",
		"enemy_category": "Convois Maritimes & Escadres Navales de Surface",
		"opposing_threat": "ssn_688i_los_angeles",
		"friendly_partner": "type_055_renhai",
		"move_act": "Vitesse en plongée de 30 kts, réacteur nucléaire à eau pressurisée avec pompe-hélice carénée.",
		"fight": "Silos VLS arrières tirant des missiles anti-navires supersoniques YJ-18 volant à ras de l'eau puis accélérant à Mach 3.",
		"defend": "Sonars latéraux à antennes synthétiques et système de contre-mesures anti-torpilles.",
		"special_trick": "Frappe Anti-Navire depuis l'Immersion Profonde : Lance ses missiles en immersion sans faire surface, perçant l'interface eau-air.",
		"friendly_integration": "Partage les informations sous-marines avec les frégates de lutte ASM Type 054A."
	},
	"orca_xluuv": {
		"title": "Boeing Orca XLUUV : Sous-Marin Autonome Géant & Minage de Détroit",
		"domain": "SEA",
		"enemy_category": "Détroits Maritimes, Passes Navales & Navires Américains/Chinois",
		"opposing_threat": "type_055_renhai",
		"friendly_partner": "ssn_688i_los_angeles",
		"move_act": "Sous-marin sans équipage de 26m de long, navigation autonome sur 10 000 km grâce à sa propulsion hybride diesel-électrique lithium-ion.",
		"fight": "Soute modulaire de 10m emportant des mines sous-marines intelligentes Quickstrike et capteurs de fond.",
		"defend": "Opère sans aucune signature biologique (pas d'équipage, pas d'air conditionné, pas de bruit humain).",
		"special_trick": "Minage Clandestine de Goulot d'Étranglement : Pose un champ de mines sous-marines au fond d'un détroit contesté sans qu'aucun navire ne soit détecté.",
		"friendly_integration": "Transmet ses rapports de renseignement par antenne furtive furtivement déployée à la surface la nuit."
	},
	"magura_v5_usv": {
		"title": "MAGURA V5 : Drone Naval Kamikaze en Meute & Harcèlement Nocturne",
		"domain": "SEA",
		"enemy_category": "Navires de Ligne de Grande Taille (Corvettes, Frégates, Navires de Débarquement)",
		"opposing_threat": "type_055_renhai",
		"friendly_partner": "sea_baby_usv",
		"move_act": "Embarcation de 5.5m profilée hydrodynamique, vitesse 42 kts, profil fuyant à 50cm au-dessus de l'eau.",
		"fight": "Charge explosive de 320 kg détonant par impact direct sur la ligne de flottaison (safran de gouvernail ou salle des machines).",
		"defend": "Navigation en zigzag nocturne, très difficile à viser avec des mitrailleuses manuelles depuis le pont d'un navire qui tangue.",
		"special_trick": "Attaque en Meute Coordonnée (Wolfpack Pincer) : 4 à 6 drones attaquent le navire sous des angles opposés à 90° d'écart, saturant la capacité de réaction des tireurs de bord.",
		"friendly_integration": "Guidé par terminal satellite Starshield avec caméras optiques et infrarouges haute définition."
	},
	"sea_baby_usv": {
		"title": "Sea Baby USV : Drone Naval Multi-Rôle, Minage & Lance-Roquettes",
		"domain": "SEA",
		"enemy_category": "Piliers de Ponts Maritimes, Bâtiments Côtiers & Ports Militaires",
		"opposing_threat": "type_055_renhai",
		"friendly_partner": "magura_v5_usv",
		"move_act": "Navire autonome lourd pouvant emporter jusqu'à 850 kg de charge explosive ou des paniers lance-roquettes.",
		"fight": "Roquettes thermobariques et mines marines déposées directement sur les rails d'accès portuaires.",
		"defend": "Blindage léger sur la partie avant et capteurs de vision nocturne stabilisés.",
		"special_trick": "Plateforme d'Artillerie Flottante : Peut tirer des roquettes contre les postes côtiers avant de se saborder sur un quai.",
		"friendly_integration": "Couvre la retraite des drones rapides Magura V5 en tirant des roquettes de diversion."
	},

	# =========================================================================
	# 11. BÂTIMENTS DE LIGNE DE SURFACE & GROUPES AÉRONAVALS (CSG)
	# =========================================================================
	"ddg_51_arleigh_burke": {
		"title": "USS Arleigh Burke Flight III : Destroyer Aegis & Dôme Anti-Missile SPY-6",
		"domain": "SEA",
		"enemy_category": "Salves de Missiles Anti-Navires Massives & Menaces Balistiques",
		"opposing_threat": "type_055_renhai",
		"friendly_partner": "cvn_78_gerald_r_ford",
		"move_act": "Turbines à gaz General Electric LM2500 propulsant 9 500 tonnes à plus de 31 kts.",
		"fight": "96 silos VLS Mk 41 armés de missiles SM-6 Dual II (anti-air, anti-navire et anti-balistique terminal) et missiles de croisière Tomahawk.",
		"defend": "Radar AESA AN/SPY-6(V)1 35 fois plus sensible que les versions précédentes, canon de point CIWS Phalanx 20mm.",
		"special_trick": "Interception Exoatmosphérique SM-3 : Détruit des missiles balistiques à 250 km d'altitude dans l'espace avant leur rentrée dans l'atmosphère.",
		"friendly_integration": "Navire sentinelle d'escorte directe du porte-avions, relié par Cooperative Engagement Capability (CEC)."
	},
	"type_055_renhai": {
		"title": "Type 055 Renhai : Croiseur Amiral Lourd & Salve VLS Hypersonique",
		"domain": "SEA",
		"enemy_category": "Groupes Aéro-Navals Adverses & Flottes de Surface",
		"opposing_threat": "ddg_51_arleigh_burke",
		"friendly_partner": "cns_fujian_cv18",
		"move_act": "Croiseur de 13 000 tonnes à propulsion COGAG assurant 30 kts en haute mer avec proue furtive.",
		"fight": "112 silos verticaux VLS grande taille tirant le missile balistique anti-navire hypersonique YJ-21 (Mach 9).",
		"defend": "Radar double bande S/X Type 346B, missiles HHQ-9B longue portée et missile de défense rapprochée HQ-10.",
		"special_trick": "Tir Hypersonique YJ-21 : Lance un missile balistique naval capable de frapper un porte-avions à 1 500 km avec une trajectoire indétectable.",
		"friendly_integration": "Bâtiment de commandement et de défense aérienne de zone pour l'ensemble du groupe aéronaval chinois."
	},
	"cvn_78_gerald_r_ford": {
		"title": "USS Gerald R. Ford (CVN-78) : Super-Porte-Avions EMALS & Sorties Aériennes Massives",
		"domain": "SEA",
		"enemy_category": "Théâtres de Guerre Entiers & Forces Armées Nationales",
		"opposing_threat": "cns_fujian_cv18",
		"friendly_partner": "ddg_51_arleigh_burke",
		"move_act": "Deux réacteurs nucléaires A1B fournissant une vitesse illimitée de 30+ kts sur 100 000 tonnes de déplacement.",
		"fight": "Embarque plus de 75 aéronefs de combat (F-35C, F/A-18F, E-2D, MQ-25) générant 160 à 220 sorties de frappe par jour.",
		"defend": "Défense en couches par ses destroyers d'escorte, missiles RIM-162 ESSM et RIM-116 RAM embarqués.",
		"special_trick": "Catapultes Électromagnétiques EMALS : Règle la force de catapultage au gramme près pour lancer des drones ultra-légers de 500 kg comme des bombardiers lourds de 35 tonnes.",
		"friendly_integration": "Centre de gravité stratégique du théâtre d'opérations projetant la puissance militaire globale."
	},
	"cns_fujian_cv18": {
		"title": "CNS Fujian (CV-18) : Super-Porte-Avions CATOBAR EMALS Chinois",
		"domain": "SEA",
		"enemy_category": "Flottes Océaniques Alliées & Défense du Pacifique Ouest",
		"opposing_threat": "cvn_78_gerald_r_ford",
		"friendly_partner": "type_055_renhai",
		"move_act": "Bâtiment de 80 000 tonnes à catapulte électromagnétique avec 3 pistes de lancement simultanées.",
		"fight": "Groupe aérien embarqué de 60 appareils incluant les chasseurs de 5e génération J-35, les J-15B et l'avion radar KJ-600.",
		"defend": "Canons rotatifs Type 1130 à 11 tubes tirant 11 000 coups/minute et missiles anti-missiles HQ-10.",
		"special_trick": "Lancement EMALS d'Avion Radar KJ-600 : Déploie un avion radar lourd à hélice en haute mer sans dépendre des bases terrestres.",
		"friendly_integration": "Protégé par une bulle de 4 destroyers Type 055 et 2 sous-marins nucléaires d'attaque."
	},
	"fs_charles_de_gaulle_r91": {
		"title": "FS Charles de Gaulle (R91) : Porte-Avions Nucléaire CATOBAR Français",
		"domain": "SEA",
		"enemy_category": "Forces Aériennes & Côtières Adverses en Méditerranée et Indo-Pacifique",
		"opposing_threat": "admiral_gorshkov_frigate",
		"friendly_partner": "rafale_f4_flight",
		"move_act": "Propulsion nucléaire K15 assurant autonomie stratégique mondiale à 27 kts.",
		"fight": "30 chasseurs Rafale Marine armés de missiles nucléaires ASMP-A, missiles Meteor et bombes guidées AASM.",
		"defend": "Système Aster 15 à lancement vertical et autodirecteur électromagnétique actif.",
		"special_trick": "Dissuasion Nucléaire Embarquée : Seul porte-avions non-américain doté de catapultes et de capacité de frappe nucléaire stratégique pré-stratégique.",
		"friendly_integration": "Intégration transparente avec les flottes alliées OTAN et forces aéro-maritimes européennes."
	},
	"admiral_gorshkov_frigate": {
		"title": "Amiral Gorshkov (Projet 22350) : Frégate Missiles Hypersoniques Zircon",
		"domain": "SEA",
		"enemy_category": "Navires Américains Aegis & Ports Militaires Côtiers",
		"opposing_threat": "ddg_51_arleigh_burke",
		"friendly_partner": "tu_22m3_backfire",
		"move_act": "Frégate polyvalente de 5 400 tonnes à turbine gaz assurant 29.5 kts avec coque furtive profilée.",
		"fight": "16 silos UKSK tirant le missile hypersonique 3M22 Zircon filant à Mach 9 (3 km/s) sur 1 000 km.",
		"defend": "Système anti-aérien Redut (32 silos verticaux) utilisant les missiles 9M96E2 et canon 130mm A-192M.",
		"special_trick": "Frappe Navale Hypersonique Mach 9 : Le missile Zircon arrive tellement vite que le temps de réaction des systèmes de défense de bord adverse est réduit à moins de 15 secondes.",
		"friendly_integration": "Agit comme éclaireur de surface pour les sous-marins nucléaires lanceurs d'engins russes."
	},
	"specops_mountain_team": {
		"title": "Special Forces Mountain Recon : Infiltration de Haute Altitude & Chiens Robots",
		"domain": "LAND",
		"enemy_category": "Postes C4ISR Fortifiés & Positions Retranchées",
		"opposing_threat": "spetsnaz_sniper_commando",
		"friendly_partner": "vision_60_q_ugv",
		"move_act": "Infiltration pédestre TBA furtive en crêtes rocheuses, progression silencieuse sous le masque du relief.",
		"fight": "Désignation laser SOFLAM pour frappes aériennes de précision et déploiement de micro-drones suicides Switchblade.",
		"defend": "Tenue de camouflage multispectrale anti-thermique, brouillage radio portatif et repli d'urgence en rappel.",
		"special_trick": "Reconnaissance Infiltrée & Désignation Laser : Révèle les cibles retranchées sans être détecté au-delà de 200m.",
		"friendly_integration": "Liaison directe avec les frappes air-sol de B-21 Raider et les chiens robots Vision 60 en éclaireurs."
	},
	"hyunmoo_5_tel": {
		"title": "Hyunmoo-5 Monster TEL : Frappe Balistique Anti-Bunker 8 Tonnes",
		"domain": "LAND",
		"enemy_category": "Bunkers Souterrains Profonds & Centres C4ISR Durcis",
		"opposing_threat": "kn_25_mlrs_battery",
		"friendly_partner": "kf_21_boramae",
		"move_act": "Déploiement sur tracteur-érecteur-lanceur 16x16 lourd, mise en batterie rapide en 180s puis repli tactique immédiat.",
		"fight": "Tir balistique quasi-orbital culminant à 300km d'altitude avec ogive cinétique pénétratrice de 8 tonnes à Mach 10+.",
		"defend": "Masquage thermique sous filets réducteurs de signature IR, dispersion géographique immédiate après tir (Shoot-and-Scoot).",
		"special_trick": "Ogive Pénétrante Géante : Pulvérise les complexes de commandement enterrés jusqu'à 100 mètres sous la roche.",
		"friendly_integration": "Guidage terminal réactualisé par les données satellitaires SAR et les chasseurs KF-21 en couverture."
	},
	"kn_25_mlrs_battery": {
		"title": "KN-25 Super-Large MLRS 600mm : Salve Balistique de Saturation Lourde",
		"domain": "LAND",
		"enemy_category": "Bases Aériennes & Nœuds Logistiques Stratégiques",
		"opposing_threat": "hyunmoo_5_tel",
		"friendly_partner": "s_400_triumf",
		"move_act": "Déplacement sur châssis chenillé tout-terrain, repositionnement éclair après chaque tir de salve.",
		"fight": "Tir en rafale de 4 roquettes guidées de calibre 600mm portant à 380km avec guidage inertiel et satellitaire.",
		"defend": "Blindage protégeant l'équipage contre les éclats d'artillerie et repli immédiat pour échapper au tir de contre-batterie.",
		"special_trick": "Saturation Super-Calibre : Saturation massive des défenses de point MIM-104 Patriot par le volume et la vitesse terminale.",
		"friendly_integration": "Coordination avec les radars de surveillance aérienne et de contre-batterie pour riposte instantanée."
	},
	"zorawar_mountain_tank": {
		"title": "Zorawar Light Tank : Combat Blindé Mobile en Très Haute Altitude (LAC)",
		"domain": "LAND",
		"enemy_category": "Chars de Combat & Blindés Moyens de Montagne (Type 15)",
		"opposing_threat": "t_90m_platoon",
		"friendly_partner": "hal_tejas_mk2",
		"move_act": "Franchissement tout-terrain agile sur pentes à 40° jusqu'à 5 000m d'altitude avec moteur turbocompressé haute altitude.",
		"fight": "Canon rayé de 105mm tirant obus flèches APFSDS et missiles antichars guidés au canon, jumelé à des munitions rôdeuses.",
		"defend": "Système de protection active (APS) modulaire léger, détection laser d'alerte et fumigènes multispectraux.",
		"special_trick": "Agilité Haut-Perchée : Tir en dépression négative depuis les crêtes himalayennes inaccessibles aux MBT lourds.",
		"friendly_integration": "Liaison tactique intégrée avec les chasseurs Tejas Mk2 et les drones de reconnaissance d'artillerie."
	},
	"hemtt_supply_convoy": {
		"title": "Oshkosh HEMTT : Convoi Logistique Lourd & Ravitaillement Express d'Essaims",
		"domain": "LAND",
		"enemy_category": "Raids de Harcèlement Commando & Drones FPV Rôdeurs",
		"opposing_threat": "lancet_3_team",
		"friendly_partner": "m1a2_sepv3_platoon",
		"move_act": "Transit routier et tout-terrain 8x8 à 70 km/h avec système centralisé de gonflage des pneus (CTIS) et autonomie de 480 km.",
		"fight": "Tourelle téléopérée CROWS calibre .50 M2HB pour autodéfense rapprochée contre les infiltrés et drones lents.",
		"defend": "Cabine blindée A-kit/B-kit résistante aux mines et IED, brouilleur anti-IED/drone Duke V3 et brouillard fumigène.",
		"special_trick": "Ravitaillement Rapide de Munitions : Réapprovisionne instantanément les stocks de missiles Patriot, HIMARS et batteries d'essaims.",
		"friendly_integration": "Réseau logistique C4ISR synchronisé réapprovisionnant automatiquement les brigades au combat en flux tendu."
	},
	"t_84_oplot_platoon": {
		"title": "T-84 Oplot-M : Choc Blindé Lourd à Blindage Réactif Duplet",
		"domain": "LAND",
		"enemy_category": "Formations Blindées Lourdes & Chars de Combat Adverses",
		"opposing_threat": "t_90m_platoon",
		"friendly_partner": "btr_4_bucephalus_co",
		"move_act": "Moteur diesel 6TD-2E à pistons opposés de 1200ch permettant 70 km/h en marche avant et 35 km/h en marche arrière rapide.",
		"fight": "Canon à âme lisse 125mm KBA-3 tirant missiles guidés laser Kombat à 5km et obus flèches à haute pénétration.",
		"defend": "Blindage réactif tandem Duplet multicouche neutralisant les charges creuses et obus APFSDS, système optronique Varta.",
		"special_trick": "Blindage Duplet Multi-Impact : Encaisse deux coups perforants successifs au même endroit sans rupture de blindage.",
		"friendly_integration": "Liaison radio cryptée tactique avec les compagnies mécanisées de BTR-4 pour couverture mutuelle."
	},
	"dn_xi_mexican_armor": {
		"title": "SEDENA DN-XI & Lynx : Cavalerie Blindée de Reconnaissance Rapide",
		"domain": "LAND",
		"enemy_category": "Colonnes Mobiles Infiltrées & Forces Dissimulées",
		"opposing_threat": "spetsnaz_sniper_commando",
		"friendly_partner": "f_5f_tiger_mex_flight",
		"move_act": "Mobilité tout-terrain 4x4/6x6 rapide jusqu'à 100 km/h, déploiement éclair sur routes et pistes semi-désertiques.",
		"fight": "Canon de 90mm moyenne pression tirant obus HEAT et HE, complété de mitrailleuses lourdes 12.7mm sur affût téléopéré.",
		"defend": "Blindage acier soudé résistant aux calibres moyens et éclats d'obus, profil bas réduisant la signature visuelle.",
		"special_trick": "Patrouille Frontalière Longue Élongation : Rayon d'action étendu sans ravitaillement pour sécurisation de corridors.",
		"friendly_integration": "Coordination radio C2 avec la flotte d'appui aérien léger F-5F et les unités de commandos terrestres."
	},
	"f_5f_tiger_mex_flight": {
		"title": "F-5E/F Tiger II : Interception Légère Supersonique & Appui Tactique",
		"domain": "AIR",
		"enemy_category": "Incursions Aériennes Transfrontalières & Cibles Terrestres Mobiles",
		"opposing_threat": "su_57_felon",
		"friendly_partner": "f_16cj_block70",
		"move_act": "Vol supersonique Mach 1.6 à 12 000m avec grand taux de montée et faible rayon de virage instantané.",
		"fight": "2 canons Pontiac M39A2 de 20mm, 2 missiles air-air AIM-9P/L Sidewinder et paniers de roquettes/bombes guidées.",
		"defend": "Lance-leurres AN/ALE-40 éjectant paillettes chaff et fusées éclairantes, récepteur d'alerte radar AN/ALR-87.",
		"special_trick": "Interception Réaction Rapide : Temps de décollage sur alerte inférieur à 3 minutes pour intercepter les intrus aériens.",
		"friendly_integration": "Liaison radio avec les postes radar au sol pour guidage d'interception contrôlé depuis la base."
	},
	"pola_benito_juarez_frigate": {
		"title": "ARM Benito Juárez (POLA-101) : Frégate Multirôle de Surveillance Maritime",
		"domain": "SEA",
		"enemy_category": "Bâtiments de Surface Intrus & Sous-Marins Côtiers",
		"opposing_threat": "type_055_renhai",
		"friendly_partner": "ddg_51_arleigh_burke",
		"move_act": "Propulsion combinée diesel ou électrique (CODOE) silencieuse à 28 nœuds, excellente tenue en mer haute.",
		"fight": "Missiles anti-navires Harpoon Block II, torpilles anti-sous-marines Mk 54 et canon 57mm Bofors tout-temps.",
		"defend": "Système de défense rapprochée RAM Block 2 contre missiles anti-navires, leurres acoustiques et brouilleurs EW.",
		"special_trick": "Discrétion Acoustique CODOE : Mode tout-électrique basse vitesse pour traquer les sous-marins sans bruit de propulsion.",
		"friendly_integration": "Système de combat collaboratif partagé avec les destroyers alliés et aéronefs de patrouille maritime."
	},
	"ins_vikrant_r11": {
		"title": "INS Vikrant (R11) : Groupe Aéronaval de Projection Indienne STOBAR",
		"domain": "SEA",
		"enemy_category": "Flottes Aéronavales Ennemies & Groupes de Chasseurs BVR",
		"opposing_threat": "cns_fujian_cv18",
		"friendly_partner": "ddg_51_arleigh_burke",
		"move_act": "Transit de groupe aéronaval à 28 nœuds propulsé par 4 turbines à gaz General Electric LM2500, tremplin ski-jump.",
		"fight": "Groupe aérien embarqué de 26 chasseurs et hélicoptères, missiles sol-air moyenne portée Barak-8 (portée 70 km).",
		"defend": "Radar 4D AESA MF-STAR, bouclier CIWS AK-630 et systèmes de leurres torpilles Kavach.",
		"special_trick": "Tremplin STOBAR Ski-Jump : Décollage sur pont incliné à 14° permettant la projection rapide de patrouilles aériennes.",
		"friendly_integration": "Centre de commandement C4ISR flottant coordonnant la bulle aéro-maritime de l'océan Indien."
	},
	"ah_64e_apache_guardian": {
		"title": "AH-64E Apache Guardian : Vol NOE & Embuscade Antichar Hellfire",
		"domain": "AIR",
		"enemy_category": "Blindés Lourds & T-90M / Tor-M2",
		"opposing_threat": "t_90m_platoon",
		"friendly_partner": "vision_60_q_ugv",
		"move_act": "Vol NOE (Nap-of-the-Earth) à 120m sol à 140 kts, masquage derrière les crêtes et les lisières de forêt.",
		"fight": "Acquisition optique IRST/Longbow, tir plongeant de missiles AGM-114 Hellfire guidés laser à 8 km puis strafe canon 30mm M230.",
		"defend": "Alerte départ missile optique, largage de leurres thermiques et rupture évasive sous le couvert des arbres.",
		"special_trick": "Embuscade Défilée de Crête : Surgit brièvement au-dessus de la ligne de crête, tire une salve Hellfire, et replonge instantanément à l'abri.",
		"friendly_integration": "Datalink Manned-Unmanned Teaming (MUM-T) avec les chiens robots Vision 60 pour la désignation laser déportée d'objectifs."
	},
	"ka_52_alligator": {
		"title": "Ka-52 Alligator : Tir Antichar Vikhr Stand-Off & Rotor Coaxial",
		"domain": "AIR",
		"enemy_category": "Colonnes Blindées M1A2 SEPv3 Abrams & Blindés Bradley",
		"opposing_threat": "m1a2_sepv3_platoon",
		"friendly_partner": "su_57_felon",
		"move_act": "Vol tactique TBA à 145 kts grâce à la portance des doubles rotors coaxiaux à haute agilité en vent de travers.",
		"fight": "Tir guidé faisceau laser de missiles antichars 9K121 Vikhr jusqu'à 10 km et tirs de saturation canon 30mm 2A42.",
		"defend": "Suite de contre-mesures intégrée Vitebsk DIRCM avec brouillage laser des autodirecteurs infrarouges.",
		"special_trick": "Vol Stationnaire Décalé Coaxial : Effectue des pivotements à 360° sur place pour engager des cibles sous n'importe quel angle sans dérive.",
		"friendly_integration": "Partage de données tactiques avec les patrouilles de Su-57 pour l'interdiction de couloirs de progression ennemis."
	},
	"columbia_class_ssbn": {
		"title": "Columbia-Class SSBN : Dissuasion Nucléaire Sous-Marine Indétectable",
		"domain": "SEA",
		"enemy_category": "Sous-Marins Nucléaires d'Attaque Chasseurs (Type 093B / Yasen-M)",
		"opposing_threat": "type_093b_shang_ssn",
		"friendly_partner": "ssn_688i_los_angeles",
		"move_act": "Patrouille silencieuse à 20-22 kts à -180m sous la thermocline, propulsion turbo-électrique sans boîte de vitesse (signature quasi-nulle).",
		"fight": "VLS pour 16 missiles balistiques stratégiques Trident II D5 LE et 4 tubes lance-torpilles Mk 48 ADCAP d'auto-défense.",
		"defend": "Revêtement anéchoïque absorbant le sonar actif, manœuvres sous la couche thermique et largage de leurres acoustiques MOSS.",
		"special_trick": "Silence Acoustique Absolu : Réduit le bruit de coque en dessous du bruit de fond de l'océan, rendant la détection passive impossible.",
		"friendly_integration": "Liaison satellite ELF/VLF sécurisée avec le bunker de commandement pour transmission des codes PAL de tir DEFCON 1."
	},
	"type_094_jin_ssbn": {
		"title": "Type 094 Jin-Class SSBN : Bastion Sous-Marin de Seconde Frappe",
		"domain": "SEA",
		"enemy_category": "Sous-marins d'attaque occidentaux (SSN-688I / Virginia / Astute)",
		"opposing_threat": "ssn_688i_los_angeles",
		"friendly_partner": "type_093b_shang_ssn",
		"move_act": "Immersion opérationnelle à -150m dans les fosses océaniques protégées de la mer de Chine méridionale à 18-20 kts.",
		"fight": "12 tubes verticaux pour missiles balistiques intercontinentaux JL-3 et torpilles lourdes filoguidées Yu-6.",
		"defend": "Emménagement dans le sanctuaire anti-sous-marin bastionné sous protection des destroyers Type 055.",
		"special_trick": "Frappe Balistique en Plongée : Capacité de tir de missiles balistiques en séquence rapide depuis l'immersion sans faire surface.",
		"friendly_integration": "Datalink acoustique et bouées relais avec les sous-marins d'escorte Type 093B formant écran de protection."
	},
	"c17_globemaster_iii": {
		"title": "C-17A Globemaster III : Pont Aérien Stratégique & Parachutage de Combat",
		"domain": "AIR",
		"enemy_category": "Systèmes SAM Longue Portée & Chasseurs d'Interception (S-400 / Su-57)",
		"opposing_threat": "s_400_triumf",
		"friendly_partner": "f_35a_lightning",
		"move_act": "Vol de transit stratégique à 420-450 kts à 11 000m, suivi d'une descente tactique rapide vers 350m pour largage.",
		"fight": "Transport de 77 tonnes de fret lourd (char Abrams, VCI Bradley, ou 102 parachutistes équipés) projetable sur piste sommaire.",
		"defend": "Système de contre-mesures infrarouges DIRCM à laser et éjecteurs de paillettes/chaff haute cadence.",
		"special_trick": "Largage Parachute de Précision : Éjection par la rampe arrière de palettes de ravitaillement guidées par GPS directement sur le front.",
		"friendly_integration": "Escorte rapprochée SEAD par patrouilles F-35A pour neutraliser les menaces sol-air sur le couloir de largage."
	},
	"il76_candid": {
		"title": "Il-76MD-90A Candid : Transport Lourd & Projection Aéroportée Tout-Terrain",
		"domain": "AIR",
		"enemy_category": "Batteries Patriot PAC-3 & Chasseurs de Supériorité Aérienne (F-35A / F-16V)",
		"opposing_threat": "mim_104f_patriot",
		"friendly_partner": "su_57_felon",
		"move_act": "Croisière à 410-440 kts sur réacteurs PS-90A-76, atterrissage et décollage sur pistes en terre non préparées.",
		"fight": "Capacité d'emport de 60 tonnes (3 blindés aéroportés BMD-4M ou 126 parachutistes d'assaut).",
		"defend": "Suite d'autoprotection President-S avec brouilleurs laser contre missiles thermiques portatifs MANPADS.",
		"special_trick": "Déploiement Massif VDV : Largage en séquence de sections blindées complètes avec parachutes rétro-fusées freinées.",
		"friendly_integration": "Couverture de zone assurée par Su-57 Felon et brouillage CEMA Krasukha-4 pour masquer la zone d'atterrissage."
	},
	"kamaz_resupply_truck": {
		"title": "KamAZ-6350 8x8 : Convoi Logistique Tactique & Ravitaillement de Munitions",
		"domain": "LAND",
		"enemy_category": "Drones Kamikazes FPV & Équipes Antichar Embousquées (Javelin / FPV Swarm)",
		"opposing_threat": "fpv_fiber_swarm",
		"friendly_partner": "t_90m_platoon",
		"move_act": "Progression en convoi tout-terrain 8x8 à 40 km/h sur pistes secondaires et zones défoncées.",
		"fight": "Approvisionnement rapide en obus 125mm, missiles Kornet, carburant diesel et munitions pour l'échelon de tête.",
		"defend": "Blindage cabine cablée, brouilleurs locaux anti-drones RP-377 et bâches de camouflage thermique.",
		"special_trick": "Ravitaillement Express sous le Feu : Réapprovisionne les blindés de combat en moins de 90 secondes en bordure de tranchée.",
		"friendly_integration": "Escorte directe assurée par pelotons T-90M et couverture aérienne par drones Lancet-3 en surveillance avancée."
	}
}


## Returns the full tactical trial specification for a platform slug.
static func get_trial_info(slug: String) -> Dictionary:
	if TRIALS_DATA.has(slug):
		return TRIALS_DATA[slug]
	# Fallback if slug contains partial name
	for k in TRIALS_DATA:
		if slug.contains(k) or k.contains(slug):
			return TRIALS_DATA[k]
	return {
		"title": "Épreuve Tactique : " + slug.capitalize(),
		"domain": "LAND",
		"enemy_category": "Menace Standard de Théâtre",
		"opposing_threat": "t_90m_platoon",
		"friendly_partner": "m1a2_sepv3_platoon",
		"move_act": "Déplacement à vitesse opérationnelle standard avec respect des corridors tactiques.",
		"fight": "Engagement cinétique direct selon la doctrine standard de l'unité.",
		"defend": "Utilisation des contre-mesures de bord et recherche de couvert.",
		"special_trick": "Coordination tactique standard d'armes combinées.",
		"friendly_integration": "Partage de données tactiques avec les unités alliées du même échelon."
	}


## Sets up a dedicated tactical proving trial scenario on the War Table.
## Spawns the subject unit, its wingman/partner, and the target enemy threat in an isolated arena.
static func setup_trial_scenario(sim_server: SimServer, platform_slug: String) -> Dictionary:
	var trial: Dictionary = get_trial_info(platform_slug)
	var st: WorldState = sim_server.world_state
	var db: Node = sim_server.sim_db_ref
	
	st.reset()
	sim_server.replay_recorder.clear()
	if sim_server.command_bus_ref != null:
		sim_server.command_bus_ref.clear_all()
		
	st.time_scale = 1.0
	st.defcon_level = 3
	
	# Resolve platform IDs
	var subj_pid: int = db.get_platform_id(platform_slug)
	var opp_slug: String = trial.get("opposing_threat", "t_90m_platoon")
	var opp_pid: int = db.get_platform_id(opp_slug)
	var friend_slug: String = trial.get("friendly_partner", "m1a2_sepv3_platoon")
	var friend_pid: int = db.get_platform_id(friend_slug)
	
	var subj_def: Dictionary = db.get_platform(subj_pid)
	var opp_def: Dictionary = db.get_platform(opp_pid)
	var friend_def: Dictionary = db.get_platform(friend_pid)
	
	var is_air: bool = (String(subj_def.get("domain", "")) == "AIR")
	var is_sea: bool = (String(subj_def.get("domain", "")) == "SEA")
	
	var subj_alt := float(subj_def.get("cruise_alt_m", 10000.0 if is_air else 0.0))
	var opp_alt := float(opp_def.get("cruise_alt_m", 10000.0 if (opp_def.get("domain", "") == "AIR") else 0.0))
	
	# Spawn Positions: Arena centered at (0, 0), Subject at (-25km, 0), Enemy at (+25km, 0)
	var subj_pos := Vector3(-25.0, subj_alt, 0.0)
	var friend_pos := Vector3(-28.0, subj_alt, 4.0)
	var opp_pos := Vector3(25.0, opp_alt, 0.0)
	
	var subj_uid := st.spawn_unit(WorldState.FACTION_BLUE, subj_pid, subj_pos, WorldState.ECHELON_COMPANY, -1, subj_def)
	var friend_uid := st.spawn_unit(WorldState.FACTION_BLUE, friend_pid, friend_pos, WorldState.ECHELON_COMPANY, -1, friend_def)
	var opp_uid := st.spawn_unit(WorldState.FACTION_RED, opp_pid, opp_pos, WorldState.ECHELON_COMPANY, -1, opp_def)
	
	# Order units to advance towards engagement
	st.unit_target_pos[subj_uid] = Vector3(15.0, subj_alt, 0.0)
	st.unit_has_waypoint[subj_uid] = 1
	st.unit_target_pos[friend_uid] = Vector3(12.0, subj_alt, 4.0)
	st.unit_has_waypoint[friend_uid] = 1
	st.unit_target_pos[opp_uid] = Vector3(-15.0, opp_alt, 0.0)
	st.unit_has_waypoint[opp_uid] = 1
	
	# Apply BVR standoff posture if aircraft
	if is_air:
		st.unit_tactical_posture[subj_uid] = WorldState.TACTICAL_POSTURE_BVR_STANDOFF
		st.unit_tactical_posture[friend_uid] = WorldState.TACTICAL_POSTURE_BVR_STANDOFF
		
	# Rebuild spatial hash & sensors
	sim_server.spatial_grid.rebuild(st)
	ElectronicWarfareSystem.step(st, db, sim_server.spatial_grid)
	SensorLoSSystem.step(st, db, sim_server.spatial_grid, sim_server.cs_kernel)
	
	return {
		"trial_title": trial["title"],
		"subject_uid": subj_uid,
		"friend_uid": friend_uid,
		"opposing_uid": opp_uid,
		"trial_data": trial
	}
