shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_opaque, cull_disabled;

// Holographic NATO Squadron / Battalion / Brigade / Robot Dog Plaque Shader
// Uses COLOR (faction RGB + alpha) and INSTANCE_CUSTOM:
//   INSTANCE_CUSTOM.r = hp_ratio (0.0..1.0)
//   INSTANCE_CUSTOM.g = echelon_norm (0.0=Company, 0.5=Battalion, 1.0=Brigade)
//   INSTANCE_CUSTOM.b = symbol_type (0.0=AIR, 0.25=LAND_ARMOR, 0.50=SAM/DEFENSE, 0.75=ROBOT_DOG/UNMANNED, 1.0=SEA)
//   INSTANCE_CUSTOM.a = has_unmanned_bay_or_selected (0.0=normal, 0.5=has_robot_dogs, 1.0=selected)

varying vec4 v_custom;
varying vec4 v_color;

void vertex() {
	v_custom = INSTANCE_CUSTOM;
	v_color = COLOR;
}

void fragment() {
	vec2 uv = UV;
	vec2 p = uv * 2.0 - 1.0;
	float ax = abs(p.x);
	float ay = abs(p.y);

	vec3 base_col = v_color.rgb;
	vec3 gold_col = vec3(1.0, 0.72, 0.0); // #FFB800 Unmanned / Robot Dog / AI Gold

	// Outer tactical frame border
	float border = step(0.80, max(ax, ay));
	// Corner reticle brackets
	float corner_mask = step(0.55, max(ax, ay)) * step(0.88, max(ax, ay));

	// Center NATO tactical icon silhouette based on INSTANCE_CUSTOM.b
	float sym_code = v_custom.b;
	float icon = 0.0;
	if (sym_code < 0.15) {
		// AIR: Delta swept wing chevron
		float chevron = 1.0 - smoothstep(0.0, 0.10, abs(p.y - abs(p.x) * 0.8 + 0.15));
		icon = chevron * step(ax, 0.55) * step(ay, 0.55);
	} else if (sym_code < 0.38) {
		// LAND ARMOR / MECH: NATO crossed X + armor track oval
		float diag1 = 1.0 - smoothstep(0.0, 0.08, abs(p.x - p.y));
		float diag2 = 1.0 - smoothstep(0.0, 0.08, abs(p.x + p.y));
		icon = max(diag1, diag2) * step(max(ax, ay), 0.52);
	} else if (sym_code < 0.62) {
		// SAM / DIRECTED ENERGY DOME: Arch + vertical missile spire
		float arch = 1.0 - smoothstep(0.0, 0.09, abs(length(p - vec2(0.0, 0.2)) - 0.42));
		float spire = (1.0 - smoothstep(0.0, 0.07, ax)) * step(ay, 0.48);
		icon = max(arch * step(p.y, 0.2), spire);
	} else if (sym_code < 0.88) {
		// QUADRUPED ROBOT DOG / FPV SWARM: Diamond core + 4 quadruped leg nodes
		float diamond = 1.0 - smoothstep(0.0, 0.09, abs(ax + ay - 0.42));
		float paws = step(length(abs(p) - vec2(0.36, 0.36)), 0.11);
		icon = max(diamond, paws);
		base_col = mix(base_col, gold_col, 0.55);
	} else {
		// NAVAL SHIP / USV: Anchor hull + bow wave
		float hull = step(ay, 0.18) * step(ax, 0.52 - p.y * 0.4);
		icon = hull;
	}

	// Bottom live HP bar (uv.y in 0.84..0.94)
	float hp_ratio = clamp(v_custom.r, 0.0, 1.0);
	float in_hp_bar = step(0.82, uv.y) * step(uv.y, 0.93) * step(0.10, uv.x) * step(uv.x, 0.90);
	float hp_fill = in_hp_bar * step((uv.x - 0.10) / 0.80, hp_ratio);
	vec3 hp_col = mix(vec3(1.0, 0.2, 0.2), vec3(0.1, 1.0, 0.6), hp_ratio);

	// Top Echelon Indicator Pips (Brigade X / Battalion II / Company I)
	float ech = v_custom.g;
	float echelon_pip = step(uv.y, 0.16) * step(0.05, uv.y) * step(ax, 0.15 + ech * 0.45);

	// Selection / Unmanned Carrier Halo Ring
	float sel_flag = v_custom.a;
	float sel_pulse = 0.0;
	if (sel_flag > 0.25) {
		sel_pulse = border * (0.6 + 0.4 * sin(TIME * 7.0));
	}

	vec3 final_rgb = vec3(0.03, 0.06, 0.10);
	final_rgb = mix(final_rgb, base_col * 1.35, clamp(border * 0.75 + corner_mask * 0.35 + icon + echelon_pip * 0.85, 0.0, 1.0));
	final_rgb = mix(final_rgb, hp_col * 1.2, hp_fill);
	if (sel_flag > 0.75) {
		final_rgb += vec3(0.85, 0.95, 1.0) * sel_pulse;
	} else if (sel_flag > 0.25) {
		final_rgb += gold_col * sel_pulse * 0.8;
	}

	ALBEDO = final_rgb;
	ALPHA = clamp(0.28 + border * 0.72 + icon * 0.70 + in_hp_bar * 0.70, 0.0, 1.0) * v_color.a;
}
