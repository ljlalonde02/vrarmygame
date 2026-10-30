shader_type spatial;
render_mode unshaded, cull_disabled;

// Phase 35: 688(I) Nuclear Submarine Periscope 3D Rolling Ocean Waves Shader
// Multi-directional Gerstner swells, whitecap foam crests, specular horizon glint,
// underwater abyssal submersion mode, and EO / NVG / FLIR thermal optics modes.

uniform float wave_height : hint_range(0.05, 3.0) = 0.55;
uniform float wave_speed : hint_range(0.2, 4.0) = 1.35;
uniform float submerged_factor : hint_range(0.0, 1.0) = 0.0;
uniform int flir_mode : hint_range(0, 2) = 0; // 0=Day EO, 1=NVG Green, 2=White-Hot Thermal

varying float v_wave_crest;
varying vec3 v_world_pos;

void vertex() {
	vec2 p = VERTEX.xz;
	float t = TIME * wave_speed;

	// 4-Octave directional Gerstner-style ocean swells + chop
	float w1 = sin(p.x * 0.45 + p.y * 0.25 + t * 1.4) * 0.55;
	float w2 = cos(p.x * 0.28 - p.y * 0.52 + t * 1.1) * 0.35;
	float w3 = sin(p.x * 1.15 + p.y * 0.85 - t * 2.1) * 0.18;
	float w4 = cos(p.x * 2.40 - p.y * 1.90 + t * 3.2) * 0.08;

	float h = (w1 + w2 + w3 + w4) * wave_height;
	VERTEX.y += h;
	v_wave_crest = clamp((h / max(wave_height, 0.01) + 0.85) * 0.58, 0.0, 1.0);
	v_world_pos = VERTEX;
}

void fragment() {
	// Fine procedural sea ripple & foam pattern
	vec2 uv_fine = v_world_pos.xz * 1.8 + vec2(TIME * 0.4, -TIME * 0.3);
	float ripple = 0.5 + 0.5 * sin(uv_fine.x * 3.1 + cos(uv_fine.y * 2.7 + TIME));
	float foam_mask = smoothstep(0.66, 0.94, v_wave_crest + ripple * 0.16);

	vec3 deep_trough = vec3(0.02, 0.16, 0.30);
	vec3 mid_swell = vec3(0.06, 0.38, 0.54);
	vec3 foam_white = vec3(0.88, 0.95, 0.99);

	vec3 col = mix(deep_trough, mid_swell, v_wave_crest);
	col = mix(col, foam_white, foam_mask * 0.82);

	// Distance horizon mist blend
	float dist_norm = clamp(length(v_world_pos.xz) / 95.0, 0.0, 1.0);
	col = mix(col, vec3(0.38, 0.62, 0.78), dist_norm * 0.55);

	// Deep underwater submersion tint when diving below Periscope Depth (> 75 ft)
	if (submerged_factor > 0.01) {
		vec3 abyss_blue = mix(vec3(0.01, 0.18, 0.28), vec3(0.0, 0.05, 0.12), submerged_factor);
		float caustic = smoothstep(0.65, 0.95, sin(v_world_pos.x * 2.0 + TIME * 1.5) * cos(v_world_pos.z * 2.0 - TIME * 1.2));
		abyss_blue += vec3(0.04, 0.38, 0.48) * caustic * (1.0 - submerged_factor * 0.6);
		col = mix(col, abyss_blue, clamp(submerged_factor * 1.2, 0.0, 0.95));
	}

	if (flir_mode == 1) {
		float lum = dot(col, vec3(0.299, 0.587, 0.114));
		col = vec3(0.06, 0.95, 0.32) * clamp(lum * 1.5, 0.05, 1.0);
	} else if (flir_mode == 2) {
		float lum = dot(col, vec3(0.299, 0.587, 0.114));
		col = vec3(clamp(lum * 1.45, 0.08, 0.98));
	}

	ALBEDO = clamp(col, vec3(0.0), vec3(1.0));
	ALPHA = 1.0;
}
