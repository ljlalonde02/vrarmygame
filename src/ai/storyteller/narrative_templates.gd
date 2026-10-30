class_name NarrativeTemplates
extends RefCounted
## Zero-API-Cost Procedural Military OPORD & FRAGO Intelligence Flash Composer.
## Generates authentic theater command dispatches tied to real-time battlefield telemetry.

const FRAGO_TEMPLATES := [
	{
		"headline": "FRAGO 01 // EW SPECTRUM SPIKE DETECTED",
		"body": "NSA/CSS SIGINT reports OPFOR 1RL257 Krasukha-4 broadband jammers active along the western coast. Standard RF-datalink drones will suffer C2 link severance inside their 115km cone—switch to Fiber-Optic FPV Swarms and Autonomous AI Vision 60 Robot Dogs."
	},
	{
		"headline": "FRAGO 02 // SATURATION SWARM INBOUND — ENGAGE DIRECTED ENERGY",
		"body": "E-3G AWACS tracks low-RCS Shahed-136 and ZALA Lancet-3 loitering munitions skimming the strait. Conserve $4.0M Patriot PAC-3 interceptors—use Iron Beam 100kW High-Energy Lasers ($2/shot) and Epirus Leonidas 30° HPM Microwave cones to fry the swarm."
	},
	{
		"headline": "FRAGO 03 // QUADRUPED ROBOT DOG RECON INSERTION",
		"body": "2nd Mechanized & SpecOps Battalions have reached the 3,800m Yushan central mountain spine. Heavy armor suffers an 82% slope penalty on >25° cliffs—press [DEPLOY UNMANNED] in <15km zoom to send Ghost Robotics Vision 60 Robot Dog packs up the ridge."
	},
	{
		"headline": "FRAGO 04 // HYPERSONIC GLIDE VEHICLE TELEMETRY",
		"body": "SBIRS overhead infrared sensors detect Mach 8+ 3M22 Zircon and Kh-47M2 Kinzhal launch plumes. Authorize B-21 Raider and LRHW Dark Eagle counter-battery strikes against OPFOR TEL citadels immediately."
	},
]


static func get_frago(index: int) -> Dictionary:
	return FRAGO_TEMPLATES[posmod(index, FRAGO_TEMPLATES.size())]
