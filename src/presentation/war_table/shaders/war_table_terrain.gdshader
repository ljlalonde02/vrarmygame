shader_type spatial;
render_mode unshaded, cull_disabled;

// Dark Obsidian Bunker + High-Contrast Volumetric Hologram Terrain Shader
// Maps 500km x 500km heightmap onto the 1.8m x 1.8m War Table with:
// - Glossy dark obsidian ocean (#05080E) + tactical 50km coordinate grid
// - 200m glowing topographic iso-contour lines (#148578)
// - Real-World GIS Continental Surround (`world_map_tex`) in 4,000km Curved Space View
// - Glowing International Sovereign Border / Demarcation Line (`sovereign_border_segment`)
// - Real-time sampling of `global uniform sampler2D fow_threat_map` & `terrain_infra_map`

global uniform sampler2D fow_threat_map : filter_linear, repeat_disable;
global uniform sampler2D terrain_infra_map : filter_linear, repeat_disable;
uniform sampler2D heightmap_tex : filter_linear, repeat_disable;
uniform sampler2D world_map_tex : filter_linear, repeat_enable;
uniform bool has_world_map_tex = false;
// [min_lon, min_lat, max_lon, max_lat] of the 500km x 500km operational theater
uniform vec4 theater_latlon_box = vec4(118.0, 22.0, 123.0, 26.5);
// [u1, v1, u2, v2] UV segment of the primary sovereign international border / DMZ / Median Line / LAC
uniform vec4 sovereign_border_segment = vec4(0.48, 0.0, 0.42, 1.0);

uniform float height_scale : hint_range(0.01, 0.35) = 0.11;
uniform float sea_level_norm : hint_range(0.0, 0.5) = 0.22;
uniform vec2 table_pan_uv = vec2(0.0, 0.0);
uniform float table_zoom : hint_range(0.12, 30.0) = 1.0;
// 0: HOLO C4ISR OBSIDIAN, 1: SATELLITE TRUE-EARTH DAYLIGHT, 2: NIGHT-VISION FLIR GREEN, 3: RETRO NORAD WOPR AMBER, 4: NATO TOPOGRAPHIC MAP
uniform int graphic_style_mode : hint_range(0, 4) = 0;

varying float v_height_norm;
varying vec2 v_map_uv;
varying vec3 v_local_pos;

vec2 map_uv_to_world_equirect_uv(vec2 map_uv) {
	// Keep 100% C0 continuity at the [0..1] 500km box boundary while expanding the outer continental surround
	// so 0.52x zoom displays a full ~2,400 km continental theater (China, Japan/Ryukyu, Philippines, etc.)
	vec2 clamped_uv = clamp(map_uv, vec2(0.0), vec2(1.0));
	vec2 outer_delta = map_uv - clamped_uv;
	vec2 cont_uv = clamped_uv + outer_delta * 1.6;
	float lon_deg = mix(theater_latlon_box.x, theater_latlon_box.z, cont_uv.x);
	float lat_deg = mix(theater_latlon_box.w, theater_latlon_box.y, cont_uv.y);
	return vec2((lon_deg + 180.0) / 360.0, clamp((90.0 - lat_deg) / 180.0, 0.001, 0.999));
}

float dist_to_segment_2d(vec2 p, vec2 a, vec2 b, out float proj_t) {
	vec2 ab = b - a;
	float len_sq = max(dot(ab, ab), 0.00001);
	proj_t = clamp(dot(p - a, ab) / len_sq, 0.0, 1.0);
	return length(p - (a + ab * proj_t));
}

void vertex() {
	// Zoomed & panned UV into the 500km core theater (or 4,000km Continental Sector when table_zoom < 1.0)
	vec2 centered_uv = (UV - vec2(0.5)) / max(table_zoom, 0.125) + vec2(0.5) + table_pan_uv;
	v_map_uv = centered_uv;

	float h = 0.0;
	if (centered_uv.x >= 0.0 && centered_uv.x <= 1.0 && centered_uv.y >= 0.0 && centered_uv.y <= 1.0) {
		h = textureLod(heightmap_tex, centered_uv, 0.0).r;
	} else if (has_world_map_tex) {
		// Sample Real-World GIS Continental Elevation outside the 500km high-res core
		vec2 w_uv = map_uv_to_world_equirect_uv(centered_uv);
		vec4 w_sample = textureLod(world_map_tex, w_uv, 0.0);
		float micro_wave = 0.02 * sin(centered_uv.x * 6.0) * cos(centered_uv.y * 6.0);
		// Map world_political_map.png sea level (0.35) to war_table sea_level_norm (0.22)
		if (w_sample.b > 0.08 || w_sample.r > 0.35) {
			float land_t = clamp((w_sample.r - 0.35) / 0.65, 0.0, 1.0);
			h = clamp(0.24 + land_t * 0.56 + micro_wave, 0.23, 0.85);
		} else {
			float sea_t = clamp(w_sample.r / 0.35, 0.0, 1.0);
			h = clamp(0.05 + sea_t * 0.15 + micro_wave * 0.4, 0.04, 0.20);
		}
	} else {
		// Fallback Continental 4,000 km procedural elevation
		float cw = sin(centered_uv.x * 2.4) * cos(centered_uv.y * 2.1) + 0.5 * sin(centered_uv.x * 5.7 - centered_uv.y * 4.3);
		h = clamp(0.18 + cw * 0.16, 0.05, 0.58);
	}
	v_height_norm = h;

	float displaced_y = max(0.0, h - sea_level_norm) * height_scale * clamp(table_zoom, 0.35, 4.0);
	// Planetary Spherical Curvature Cap when zoomed out into Continental Space View (table_zoom < 1.0)
	float curve_factor = clamp((1.0 - table_zoom) / 0.65, 0.0, 1.0);
	float r2 = dot(VERTEX.xz, VERTEX.xz);
	float planet_dome_y = max(0.0, 0.145 * (1.0 - r2 / 1.65)) * curve_factor;

	VERTEX.y += displaced_y + planet_dome_y;
	v_local_pos = VERTEX;
}

void fragment() {
	if (v_map_uv.x < -3.5 || v_map_uv.x > 4.5 || v_map_uv.y < -3.5 || v_map_uv.y > 4.5) {
		ALBEDO = vec3(0.015, 0.022, 0.038);
		ALPHA = 1.0;
	} else {
		vec3 obsidian_sea = vec3(0.02, 0.03, 0.055);      // #05080E
		vec3 land_base = vec3(0.03, 0.08, 0.095);
		vec3 contour_emerald = vec3(0.08, 0.52, 0.47);   // #148578
		vec3 nato_cyan = vec3(0.0, 0.85, 1.0);           // #00D8FF
		vec3 opfor_crimson = vec3(1.0, 0.165, 0.33);     // #FF2A54

		// 50km major grid + 10km tactical sub-grid
		vec2 grid_10 = abs(fract(v_map_uv * 50.0 - 0.5) - 0.5) / max(fwidth(v_map_uv * 50.0), vec2(0.001));
		float line_10 = 1.0 - min(min(grid_10.x, grid_10.y), 1.0);
		vec2 grid_50 = abs(fract(v_map_uv * 10.0 - 0.5) - 0.5) / max(fwidth(v_map_uv * 10.0), vec2(0.001));
		float line_50 = 1.0 - min(min(grid_50.x, grid_50.y), 1.0);

		bool outside_core = (v_map_uv.x < 0.0 || v_map_uv.x > 1.0 || v_map_uv.y < 0.0 || v_map_uv.y > 1.0);

		// Sample per-fragment height so coastlines & borders are razor-sharp even between the 128x128 mesh vertices
		float frag_h = v_height_norm;
		vec4 w_pol = vec4(0.0);
		if (!outside_core) {
			frag_h = texture(heightmap_tex, v_map_uv).r;
		} else if (has_world_map_tex) {
			vec2 w_uv = map_uv_to_world_equirect_uv(v_map_uv);
			w_pol = textureLod(world_map_tex, w_uv, 0.0);
			if (w_pol.b > 0.08 || w_pol.r > 0.35) {
				float land_t = clamp((w_pol.r - 0.35) / 0.65, 0.0, 1.0);
				frag_h = 0.24 + land_t * 0.56;
			} else {
				frag_h = clamp(w_pol.r / 0.35, 0.0, 1.0) * 0.20;
			}
		}

		vec3 color = obsidian_sea;
		if (frag_h <= sea_level_norm) {
			// Ocean bathymetry rings + subtle obsidian grid
			float depth_factor = clamp(frag_h / max(sea_level_norm, 0.01), 0.0, 1.0);
			float coast_glow = smoothstep(0.82, 1.0, depth_factor);
			if (graphic_style_mode == 1) {
				// Style 1: SATELLITE TRUE-EARTH DAYLIGHT (GEOINT EO)
				vec3 deep_ocean = vec3(0.04, 0.18, 0.38);
				vec3 shallow_shelf = vec3(0.10, 0.44, 0.66);
				color = mix(deep_ocean, shallow_shelf, depth_factor);
				color += vec3(0.28, 0.72, 0.88) * coast_glow * 0.28;
				color += vec3(0.12, 0.35, 0.52) * (line_50 * 0.18 + line_10 * 0.05);
			} else if (graphic_style_mode == 4) {
				// Style 4: NATO TOPOGRAPHIC SITUATION MAP
				color = mix(vec3(0.10, 0.22, 0.36), vec3(0.18, 0.36, 0.54), depth_factor);
				color += vec3(0.32, 0.62, 0.82) * coast_glow * 0.25;
				color += vec3(0.06, 0.14, 0.24) * (line_50 * 0.28 + line_10 * 0.10);
			} else {
				color = mix(obsidian_sea * 0.75, vec3(0.03, 0.11, 0.16), depth_factor);
				color += nato_cyan * coast_glow * 0.22;
				color += vec3(0.0, 0.28, 0.38) * (line_50 * 0.25 + line_10 * 0.08);
			}
		} else {
			// Land elevation (0m to 3800m -> 19 iso-contour intervals of 200m)
			float elev_norm = (frag_h - sea_level_norm) / (1.0 - sea_level_norm);
			float elev_m = elev_norm * 3800.0;
			float contour_phase = elev_m / 200.0;
			float contour_dist = abs(fract(contour_phase - 0.5) - 0.5) / max(fwidth(contour_phase), 0.001);
			float iso_line = 1.0 - clamp(contour_dist, 0.0, 1.0);

			// Highlight 1000m major mountain ridges brighter
			float major_phase = elev_m / 1000.0;
			float major_dist = abs(fract(major_phase - 0.5) - 0.5) / max(fwidth(major_phase), 0.001);
			float major_line = 1.0 - clamp(major_dist, 0.0, 1.0);

			if (graphic_style_mode == 1) {
				// Style 1: SATELLITE TRUE-EARTH DAYLIGHT — lush lowlands, arid foothills, grey granite & alpine snow caps (>2100m)
				vec3 coastal_green = vec3(0.15, 0.36, 0.16);
				vec3 upland_olive = vec3(0.34, 0.42, 0.22);
				vec3 alpine_rock = vec3(0.46, 0.43, 0.38);
				vec3 snow_peak = vec3(0.90, 0.93, 0.96);
				color = mix(coastal_green, upland_olive, smoothstep(0.0, 0.35, elev_norm));
				color = mix(color, alpine_rock, smoothstep(0.30, 0.65, elev_norm));
				color = mix(color, snow_peak, smoothstep(0.55, 0.85, elev_norm));
				color = mix(color, color * 0.82, iso_line * 0.35);
				color += vec3(0.18, 0.22, 0.16) * (line_50 * 0.15 + line_10 * 0.05);
			} else if (graphic_style_mode == 4) {
				// Style 4: NATO TOPOGRAPHIC SITUATION MAP — warm parchment/ivory paper relief with crisp dark brown/charcoal contour lines
				vec3 paper_low = vec3(0.68, 0.74, 0.62);
				vec3 paper_mid = vec3(0.80, 0.76, 0.64);
				vec3 paper_high = vec3(0.72, 0.64, 0.54);
				color = mix(paper_low, paper_mid, smoothstep(0.0, 0.45, elev_norm));
				color = mix(color, paper_high, smoothstep(0.45, 0.90, elev_norm));
				color = mix(color, vec3(0.26, 0.20, 0.14), iso_line * 0.55);
				color = mix(color, vec3(0.12, 0.08, 0.05), major_line * 0.75);
				color = mix(color, vec3(0.15, 0.22, 0.30), line_50 * 0.28 + line_10 * 0.10);
			} else {
				color = mix(land_base, vec3(0.06, 0.22, 0.24), clamp(elev_norm * 1.2, 0.0, 1.0));
				color += contour_emerald * iso_line * 0.65;
				color += mix(contour_emerald, nato_cyan, 0.5) * major_line * 0.55;
				color += contour_emerald * (line_50 * 0.18 + line_10 * 0.06);
			}
		}

		// Render Real-World GIS Country Borders, Coastlines, Faction Alignment & Capital Lights in the 4,000km Continental Surround
		if (outside_core && has_world_map_tex) {
			float w_border = w_pol.g;
			float w_align = w_pol.b;
			float w_city = w_pol.a;

			// Crisp continental coastline glow
			float coast_edge = 1.0 - smoothstep(0.0, 0.045, abs(w_pol.r - 0.35));
			color += nato_cyan * coast_edge * 0.55;

			vec3 fac_tint = vec3(0.14, 0.78, 0.58);
			if (w_align > 0.70) {
				fac_tint = opfor_crimson;
			} else if (w_align > 0.15 && w_align < 0.33) {
				fac_tint = nato_cyan;
			}
			if (w_align > 0.08 || frag_h > sea_level_norm) {
				color = mix(color, fac_tint * 0.42 + vec3(0.04, 0.16, 0.18), 0.42);
			}
			color += mix(vec3(1.0, 0.85, 0.30), fac_tint, 0.45) * smoothstep(0.08, 0.75, w_border) * 1.15;
			color += vec3(1.0, 0.88, 0.38) * smoothstep(0.10, 0.85, w_city) * 1.10;
		}

		// Highlight the 500km Operational Core Box when in 4,000km Continental Curved View
		if (table_zoom < 0.98) {
			float box_edge_x = min(abs(v_map_uv.x), abs(v_map_uv.x - 1.0));
			float box_edge_y = min(abs(v_map_uv.y), abs(v_map_uv.y - 1.0));
			if ((v_map_uv.x >= -0.02 && v_map_uv.x <= 1.02 && box_edge_y < 0.015) ||
				(v_map_uv.y >= -0.02 && v_map_uv.y <= 1.02 && box_edge_x < 0.015)) {
				color += nato_cyan * 0.65;
			}
		}

		// Sample Global Fog-of-War, SAM Threat, Civilian Density, Infrastructure (Forests/Rivers/Roads/Rails) & War Destruction inside [0..1] Core
		if (!outside_core) {
			vec4 fow = texture(fow_threat_map, v_map_uv);
			vec4 infra = texture(terrain_infra_map, v_map_uv);
			// Guard against Godot's default unbound white (1,1,1,1) global sampler fallback
			if (fow.r > 0.98 && fow.g > 0.98 && fow.b > 0.98 && fow.a > 0.98) {
				fow = vec4(0.0);
			}
			if (infra.r > 0.98 && infra.g > 0.98 && infra.b > 0.98 && infra.a > 0.98) {
				infra = vec4(0.0);
			}

			float blue_los = fow.r;
			float red_sam = fow.g;
			float civ_density_norm = fow.b;
			float hazard_or_flux = fow.a;

			float forest_density = infra.r;
			float river_mask = infra.g;
			float road_rail_mask = infra.b;
			float destr_level = infra.a;

			// 0. Render Glowing Dashed International Border / Sovereign Demarcation Line (DMZ / Median Line / LAC / Suwalki)
			float seg_t = 0.0;
			float border_d = dist_to_segment_2d(v_map_uv, sovereign_border_segment.xy, sovereign_border_segment.zw, seg_t);
			float dash_pattern = step(0.35, fract(seg_t * 28.0));
			float border_core = (1.0 - smoothstep(0.0012, 0.0050, border_d)) * dash_pattern;
			float border_halo = 1.0 - smoothstep(0.003, 0.014, border_d);
			vec3 border_amber_crimson = mix(vec3(1.0, 0.78, 0.18), opfor_crimson, 0.45);
			color += border_amber_crimson * (border_core * 0.72 + border_halo * 0.18);

			// 1. Render Nature / Dense Forest Canopy on land
			if (frag_h > sea_level_norm && forest_density > 0.15) {
				vec3 forest_moss = vec3(0.04, 0.34, 0.19);
				color = mix(color, color + forest_moss * 0.45, clamp(forest_density, 0.0, 1.0));
			}

			// 2. Render Hydrological Downhill Rivers (glowing sapphire/cyan water channels)
			if (frag_h > sea_level_norm && river_mask > 0.25) {
				vec3 river_col = vec3(0.0, 0.68, 0.96);
				color = mix(color, river_col * 0.65, clamp(river_mask * 0.85, 0.0, 1.0));
			}

			// 3. Render Spreading Civilian Demographic Density Field (amber/gold C4ISR base heatmap + iso-density contour rings on land)
			if (frag_h > sea_level_norm && civ_density_norm > 0.03) {
				vec3 civ_amber = vec3(0.95, 0.62, 0.12);
				vec3 civ_core_gold = vec3(1.0, 0.88, 0.42);
				float civ_iso_phase = civ_density_norm * 6.0;
				float civ_iso_dist = abs(fract(civ_iso_phase - 0.5) - 0.5) / max(fwidth(civ_iso_phase), 0.015);
				float civ_iso_ring = 1.0 - clamp(civ_iso_dist, 0.0, 1.0);

				float area_glow = smoothstep(0.03, 0.92, civ_density_norm);
				color = mix(color, color + civ_amber * 0.26, area_glow * 0.58);
				color += civ_core_gold * civ_iso_ring * area_glow * 0.30;
			}

			// 4. Render High-Contrast Inter-City Highway Corridors, Railways & Procedural Metropolitan City Street Grid ON TOP of Urban Glow
			if (frag_h > sea_level_norm && (road_rail_mask > 0.20 || civ_density_norm > 0.04)) {
				float urban_presence = clamp(max(civ_density_norm * 1.35, road_rail_mask * 0.85), 0.0, 1.0);

				// 4a. Sub-Kilometer Procedural Urban Street Grid & Arterial Boulevards inside Cities/Towns
				vec2 blvd_uv = v_map_uv * 250.0; // ~2.0 km Major City Arterial Boulevards
				vec2 blvd_dist = abs(fract(blvd_uv - 0.5) - 0.5) / max(fwidth(blvd_uv), vec2(0.008));
				float blvd_line = 1.0 - clamp(min(blvd_dist.x, blvd_dist.y), 0.0, 1.0);

				vec2 street_uv = v_map_uv * 750.0; // ~660m Fine Urban City Block Street Grid
				vec2 street_dist = abs(fract(street_uv - 0.5) - 0.5) / max(fwidth(street_uv), vec2(0.012));
				float street_line = (1.0 - clamp(min(street_dist.x, street_dist.y), 0.0, 1.0)) * smoothstep(0.08, 0.45, urban_presence);

				// Darken city block interiors slightly for crisp street-to-block architectural contrast
				color = mix(color, color * 0.78, urban_presence * 0.35 * (1.0 - max(blvd_line, street_line)));

				vec3 street_col = vec3(0.42, 0.92, 0.98);     // Crisp C4ISR cyan-silver secondary city streets
				vec3 blvd_col = vec3(1.0, 0.94, 0.72);        // Warm platinum-gold major arterial boulevards
				color = mix(color, street_col, street_line * urban_presence * 0.52);
				color = mix(color, blvd_col, blvd_line * urban_presence * 0.78);

				// 4b. Inter-City Strategic Highway & Railway Trunk Corridors (`road_rail_mask`)
				if (road_rail_mask > 0.22) {
					vec3 asphalt_bed = vec3(0.05, 0.08, 0.12);
					vec3 intact_hwy = mix(vec3(1.0, 0.82, 0.28), vec3(1.0, 0.97, 0.86), blvd_line * 0.65);
					vec3 severed_hwy = vec3(0.98, 0.22, 0.12);
					vec3 hwy_col = mix(intact_hwy, severed_hwy, clamp(destr_level * 1.4, 0.0, 1.0));
					float hwy_strength = smoothstep(0.20, 0.78, road_rail_mask);
					color = mix(color, asphalt_bed, hwy_strength * 0.35);
					color = mix(color, hwy_col, hwy_strength * 0.76);
				}
			}

			// 5. Render Dynamic War Destruction (Scorched Craters, Collapsed Urban Rubble & Charred Forest Scars)
			if (destr_level > 0.12) {
				vec3 scorched_ash = vec3(0.16, 0.05, 0.04);
				vec3 ember_crater = vec3(0.95, 0.26, 0.08);
				float ember_ring = smoothstep(0.35, 0.85, destr_level);
				color = mix(color, scorched_ash, clamp(destr_level * 0.72, 0.0, 0.85));
				color += ember_crater * ember_ring * 0.42;
			}

			// Render Wind-Advected Environmental Contamination / Hazard Plume (Bio-Lime / Violet Iso-Plume)
			if (hazard_or_flux > 0.08) {
				vec3 haz_lime = vec3(0.55, 1.0, 0.15);
				vec3 haz_violet = vec3(0.85, 0.20, 1.0);
				float h_phase = hazard_or_flux * 5.0;
				float h_dist = abs(fract(h_phase - 0.5) - 0.5) / max(fwidth(h_phase), 0.02);
				float h_ring = 1.0 - clamp(h_dist, 0.0, 1.0);
				color = mix(color, color + mix(haz_lime, haz_violet, 0.35) * 0.50, clamp(hazard_or_flux, 0.0, 1.0));
				color += haz_lime * h_ring * 0.45;
			}

			color += nato_cyan * blue_los * 0.15;
			color = mix(color, color + opfor_crimson * 0.32, clamp(red_sam, 0.0, 1.0));
		}

		// Apply Full-Table Style Post-Grading for Night-Vision FLIR Green (2) and Retro NORAD WOPR Amber (3)
		if (graphic_style_mode == 2) {
			// Style 2: NIGHT-VISION FLIR GREEN (AN/AAQ-33 Targeting Pod Phosphor)
			float lum = dot(color, vec3(0.299, 0.587, 0.114));
			float scanline = 0.92 + 0.08 * sin(v_map_uv.y * 900.0);
			vec3 flir_green = vec3(0.06, 0.96, 0.28) * clamp(lum * 1.65 + 0.03, 0.02, 1.0) * scanline;
			// Preserve hot thermal white-green highlights on cities, roads, and SAM zones
			flir_green += vec3(0.45, 1.0, 0.62) * smoothstep(0.42, 0.88, lum) * 0.45;
			color = flir_green;
		} else if (graphic_style_mode == 3) {
			// Style 3: RETRO NORAD WOPR AMBER (1983 Vector CRT)
			float lum = dot(color, vec3(0.299, 0.587, 0.114));
			float crt_scan = 0.90 + 0.10 * cos(v_map_uv.y * 800.0);
			vec3 wopr_amber = vec3(1.0, 0.58, 0.06) * clamp(lum * 1.75 + 0.015, 0.01, 1.0) * crt_scan;
			wopr_amber += vec3(1.0, 0.88, 0.36) * smoothstep(0.38, 0.85, lum) * 0.48;
			color = wopr_amber;
		}

		ALBEDO = clamp(color, vec3(0.0), vec3(0.95));
		ALPHA = 1.0;
	}
}
