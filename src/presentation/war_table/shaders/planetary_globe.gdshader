shader_type spatial;
render_mode unshaded, cull_back;

// 3D Holographic Planetary Earth Shader for Tier 4 Orbital View (40,000 km Whole Planet)
// Uses Real-World Natural Earth Admin-0 Country Polygons + Orographic DEM (`world_political_map.png`):
//   R = Elevation & Bathymetry (0..0.35 Ocean Depth, 0.36..1.0 Land Elevation & Mountain Ridges)
//   G = Anti-Aliased International Country Borders & Sovereign Coastlines (0..1)
//   B = Sovereign Geopolitical Alignment (0.25 = NATO/Allies, 0.40 = Neutral, 0.55 = Regional, 0.85 = OPFOR)
//   A = Major World Capitals & C4ISR Strategic Megacity Nodes (0..1)

uniform sampler2D world_map_tex : filter_linear, repeat_enable;
uniform bool has_world_map_tex = false;

varying vec3 v_sphere_dir;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float amp = 0.5;
	for (int i = 0; i < 4; i++) {
		v += amp * value_noise(p);
		p *= 2.05;
		amp *= 0.5;
	}
	return v;
}

// Fallback procedural continental elevation if texture is not bound
float sample_continent_elevation(float lat_deg, float lon_deg) {
	vec2 uv_noise = vec2(lon_deg * 0.045, lat_deg * 0.055);
	float n = fbm(uv_noise + vec2(3.7, 1.9));
	float eurasia = exp(-pow((lon_deg - 82.0) / 52.0, 2.0) - pow((lat_deg - 44.0) / 24.0, 2.0));
	float arabia = 0.85 * exp(-pow((lon_deg - 48.0) / 14.0, 2.0) - pow((lat_deg - 24.0) / 11.0, 2.0));
	float india = 0.90 * exp(-pow((lon_deg - 80.0) / 11.0, 2.0) - pow((lat_deg - 22.0) / 13.0, 2.0));
	float east_asia = 0.88 * exp(-pow((lon_deg - 116.0) / 15.0, 2.0) - pow((lat_deg - 32.0) / 14.0, 2.0));
	float europe = 0.85 * exp(-pow((lon_deg - 18.0) / 22.0, 2.0) - pow((lat_deg - 51.0) / 13.0, 2.0));
	float africa = 0.88 * exp(-pow((lon_deg - 18.0) / 22.0, 2.0) - pow((lat_deg - 2.0) / 26.0, 2.0));
	float n_america = 0.88 * exp(-pow((lon_deg + 98.0) / 28.0, 2.0) - pow((lat_deg - 44.0) / 20.0, 2.0));
	float s_america = 0.85 * exp(-pow((lon_deg + 60.0) / 16.0, 2.0) - pow((lat_deg + 18.0) / 24.0, 2.0));
	float australia = 0.80 * exp(-pow((lon_deg - 134.0) / 16.0, 2.0) - pow((lat_deg + 25.0) / 11.0, 2.0));
	float macro_land = max(max(max(eurasia, arabia), max(india, east_asia)), max(max(europe, africa), max(max(n_america, s_america), australia)));
	return clamp(macro_land * 0.72 + (n - 0.42) * 0.55, 0.0, 1.0);
}

void vertex() {
	v_sphere_dir = normalize(VERTEX);
}

void fragment() {
	vec3 dir = normalize(v_sphere_dir);
	float lat_rad = asin(clamp(dir.y, -1.0, 1.0));
	// Right-handed sphere (+Y North, +Z front): East (+lon) rotates counter-clockwise around +Y -> atan(-dir.z, dir.x)
	float lon_rad = atan(-dir.z, dir.x);
	float lat_deg = degrees(lat_rad);
	float lon_deg = degrees(lon_rad);

	vec3 obsidian_ocean = vec3(0.015, 0.032, 0.065);
	vec3 land_emerald = vec3(0.035, 0.15, 0.18);
	vec3 ridge_teal = vec3(0.09, 0.55, 0.52);
	vec3 nato_cyan = vec3(0.0, 0.85, 1.0);
	vec3 opfor_crimson = vec3(1.0, 0.18, 0.34);
	vec3 regional_emerald = vec3(0.12, 0.72, 0.55);
	vec3 capital_gold = vec3(1.0, 0.86, 0.35);

	// 15-degree Latitude / Longitude Graticule Grid
	float lat_grid_phase = lat_deg / 15.0;
	float lon_grid_phase = lon_deg / 15.0;
	float lat_line = 1.0 - clamp(abs(fract(lat_grid_phase - 0.5) - 0.5) / max(fwidth(lat_grid_phase), 0.02), 0.0, 1.0);
	float lon_line = 1.0 - clamp(abs(fract(lon_grid_phase - 0.5) - 0.5) / max(fwidth(lon_grid_phase), 0.02), 0.0, 1.0);
	float graticule = max(lat_line, lon_line);
	float equator = 1.0 - smoothstep(0.0, 1.1, abs(lat_deg));

	// Sample Real-World GIS Political & Topographic Texture (`world_political_map.png`)
	vec2 globe_uv = vec2((lon_deg + 180.0) / 360.0, (90.0 - lat_deg) / 180.0);
	vec4 wmap = texture(world_map_tex, globe_uv);
	float fine_noise = (fbm(vec2(lon_deg * 0.22, lat_deg * 0.22)) - 0.5) * 0.06;

	float h = 0.0;
	float border_mask = 0.0;
	float align_code = 0.0;
	float city_lights = 0.0;

	if (has_world_map_tex || (wmap.r + wmap.g + wmap.b) > 0.01) {
		h = clamp(wmap.r + fine_noise, 0.0, 1.0);
		border_mask = wmap.g;
		align_code = wmap.b;
		city_lights = wmap.a;
	} else {
		h = sample_continent_elevation(lat_deg, lon_deg);
	}

	float sea_level = 0.35;
	bool is_land = (align_code > 0.08) || (h > sea_level);

	vec3 col = obsidian_ocean;
	if (is_land) {
		float land_norm = clamp((h - sea_level) / (1.0 - sea_level), 0.0, 1.0);
		float contour_phase = land_norm * 5.0;
		float contour_line = 1.0 - clamp(abs(fract(contour_phase - 0.5) - 0.5) / max(fwidth(contour_phase), 0.03), 0.0, 1.0);

		// Determine sovereign geopolitical bloc color from B channel
		vec3 bloc_col = regional_emerald;
		if (align_code > 0.70) {
			bloc_col = opfor_crimson;
		} else if (align_code > 0.15 && align_code < 0.33) {
			bloc_col = nato_cyan;
		} else if (align_code >= 0.33 && align_code < 0.48) {
			bloc_col = vec3(0.72, 0.68, 0.32);
		}

		col = mix(land_emerald, ridge_teal * 0.62, land_norm);
		// Subtle sovereign territory tint preserving the dark obsidian hologram aesthetic
		col = mix(col, bloc_col * 0.42, 0.24);
		// Topographic iso-contour ridges (Himalayas, Zagros, Alps, Andes, Rockies)
		col += mix(ridge_teal, bloc_col, 0.35) * contour_line * 0.38;
		// Crisp International Country Borders & Sovereign Coastlines
		col += mix(nato_cyan, bloc_col, 0.55) * smoothstep(0.12, 0.85, border_mask) * 0.92;
		// Glowing Golden World Capitals & C4ISR Megacity Hubs
		col += capital_gold * smoothstep(0.10, 0.90, city_lights) * 1.15;
		col += nato_cyan * graticule * 0.12;
	} else {
		float shelf = smoothstep(sea_level - 0.14, sea_level, h);
		col = mix(obsidian_ocean, vec3(0.02, 0.10, 0.17), shelf);
		col += nato_cyan * smoothstep(0.15, 0.90, border_mask) * 0.55;
		col += vec3(0.0, 0.35, 0.52) * graticule * 0.26;
	}

	col += nato_cyan * equator * 0.42;

	// Atmospheric Fresnel Rim Glow
	float ndotv = abs(dot(NORMAL, VIEW));
	float fresnel = pow(clamp(1.0 - ndotv, 0.0, 1.0), 2.6);
	col += nato_cyan * fresnel * 0.85;

	ALBEDO = col;
	ALPHA = 0.96;
}
