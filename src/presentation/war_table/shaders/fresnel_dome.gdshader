shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_back;

// Translucent Fresnel Threat & Sensor Dome Shader
// Crystal clear in the center so tokens inside remain 100% legible, glowing brightly at the grazing rim & terrain intersection.

uniform vec4 dome_color : source_color = vec4(1.0, 0.165, 0.33, 0.45);
uniform float fresnel_power : hint_range(1.0, 6.0) = 2.8;
uniform float pulse_speed : hint_range(0.0, 8.0) = 2.2;

void fragment() {
	float ndotv = clamp(abs(dot(NORMAL, VIEW)), 0.0, 1.0);
	float fresnel = pow(1.0 - ndotv, fresnel_power);

	// Horizontal latitude radar sweep rings
	float ring_pattern = sin(UV.y * 36.0 - TIME * pulse_speed) * 0.5 + 0.5;
	float equator_skirt = smoothstep(0.35, 0.52, UV.y);

	float alpha = (fresnel * 0.78 + ring_pattern * 0.12 + equator_skirt * 0.25) * dome_color.a;
	ALBEDO = dome_color.rgb * (1.1 + fresnel * 0.8);
	ALPHA = clamp(alpha, 0.0, 0.85);
}
