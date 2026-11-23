shader_type canvas_item;

uniform vec4 base_color_top : source_color = vec4(0.04, 0.05, 0.12, 1.0);
uniform vec4 base_color_bottom : source_color = vec4(0.09, 0.03, 0.18, 1.0);
uniform vec4 accent_color : source_color = vec4(0.20, 0.85, 1.00, 1.0);
uniform float beat_pulse : hint_range(0.0, 1.0) = 0.0;
uniform float energy_level : hint_range(0.0, 1.0) = 0.25;
uniform int intensity_tier : hint_range(0, 3) = 0;
uniform float drop_halo_amount : hint_range(0.0, 1.0) = 0.0;
uniform vec4 lane_hit_energies = vec4(0.0, 0.0, 0.0, 0.0);
uniform float bass_energy : hint_range(0.0, 1.0) = 0.0;
uniform float mid_energy : hint_range(0.0, 1.0) = 0.0;
uniform float high_energy : hint_range(0.0, 1.0) = 0.0;
uniform float zoom_bounce : hint_range(0.0, 0.25) = 0.0;
uniform vec2 shake_offset = vec2(0.0, 0.0);
uniform float aspect_ratio : hint_range(0.25, 4.0) = 0.5625;
uniform float perimeter_wave_enabled : hint_range(0.0, 1.0) = 0.0;
uniform float edge_glow_intensity : hint_range(0.0, 1.5) = 0.0;
uniform float edge_glow_width : hint_range(0.005, 0.05) = 0.012;
uniform float edge_drop_boost : hint_range(0.0, 1.0) = 0.0;
uniform float wave_amplitude : hint_range(0.0, 2.0) = 0.65;
uniform float lateral_wave_boost : hint_range(1.0, 2.5) = 1.60;
uniform float wave_blur_intensity : hint_range(0.0, 0.52) = 0.10;
uniform vec4 edge_primary_color : source_color = vec4(0.28, 0.86, 1.00, 1.0);
uniform vec4 edge_drop_color : source_color = vec4(0.46, 0.92, 1.00, 1.0);

void fragment() {
	float zoom_scale = 1.0 / (1.0 + (zoom_bounce * 0.16));
	vec2 uv = clamp(((UV - vec2(0.5)) * zoom_scale) + vec2(0.5) + shake_offset, vec2(0.0), vec2(1.0));

	float tier_factor = float(intensity_tier) / 3.0;
	float drop_active = clamp(drop_halo_amount, 0.0, 1.0);

	vec3 drop_tint = vec3(0.95, 0.22, 0.78) * (drop_active * (0.10 + 0.12 * bass_energy));
	vec3 boosted_bottom = base_color_bottom.rgb + (accent_color.rgb * (0.10 * bass_energy + 0.07 * mid_energy)) + drop_tint;
	vec4 bg = mix(base_color_top, vec4(boosted_bottom, 1.0), uv.y);

	float normal_pulse = clamp(max(beat_pulse, bass_energy * 0.90), 0.0, 1.0);
	float normal_horizon_sharpness = mix(13.0, 7.8, normal_pulse);
	float drop_horizon_sharpness = 10.5 - (drop_active * 1.8);
	float horizon_glow = exp(-abs(uv.y - 0.84) * mix(normal_horizon_sharpness, drop_horizon_sharpness, drop_active));

	float normal_boost = clamp(
		0.14 + (normal_pulse * (0.34 + (0.10 * energy_level))),
		0.14,
		0.58
	);
	float drop_boost = clamp(
		(beat_pulse * (0.22 + 0.18 * energy_level + 0.10 * tier_factor)) + (bass_energy * 0.16),
		0.0,
		0.56
	);
	float pulse_boost = clamp(mix(normal_boost, drop_boost, drop_active), 0.0, 0.58);

	float wave_speed = 1.2 + (drop_active * 1.1) + (mid_energy * 0.8);
	float wave = sin((uv.y * 18.0) - (TIME * wave_speed)) * 0.5 + 0.5;
	float harmonic = sin((uv.x * 12.0) + (uv.y * 28.0) - (TIME * 2.2)) * 0.5 + 0.5;
	float grid_shimmer = clamp(
		(wave * horizon_glow * (0.04 + (0.10 * mid_energy) + (0.08 * beat_pulse) + (0.04 * energy_level)))
			+ (harmonic * horizon_glow * high_energy * 0.07),
		0.0,
		0.20
	);

	vec2 shock_center = vec2(0.5, 0.84);
	float radial_dist = length((uv - shock_center) * vec2(1.0, 1.65));
	float ring_wave = sin((radial_dist * 14.0) - (TIME * (2.4 + bass_energy * 1.4))) * 0.5 + 0.5;
	float shock_envelope = exp(-radial_dist * 3.2) * (0.35 + 0.65 * max(beat_pulse, bass_energy));
	float drop_shockwave = clamp(
		drop_active * pow(ring_wave, 3.0) * shock_envelope * (0.22 + 0.10 * tier_factor),
		0.0,
		0.24
	);

	int lane_idx = clamp(int(floor(uv.x * 4.0)), 0, 3);
	float lane_energy = 0.0;
	if (lane_idx == 0) {
		lane_energy = lane_hit_energies.x;
	} else if (lane_idx == 1) {
		lane_energy = lane_hit_energies.y;
	} else if (lane_idx == 2) {
		lane_energy = lane_hit_energies.z;
	} else {
		lane_energy = lane_hit_energies.w;
	}

	float lane_center_x = (float(lane_idx) + 0.5) * 0.25;
	float dist_to_lane = abs(uv.x - lane_center_x);
	float lane_mask = exp(-dist_to_lane * 22.0);
	float lane_core_mask = exp(-dist_to_lane * 56.0);
	float vertical_fade = smoothstep(0.08, 0.96, uv.y);
	float perfect_boost = smoothstep(0.75, 1.0, lane_energy);
	float lane_flash = (lane_energy * lane_mask * 0.46 + perfect_boost * lane_core_mask * 0.42) * vertical_fade;

	vec3 perfect_tint = mix(accent_color.rgb, vec3(0.55, 1.0, 0.96), perfect_boost * 0.65);
	vec3 drop_ring_color = mix(accent_color.rgb, vec3(1.0, 0.42, 0.88), 0.55);

	vec3 raw_rgb = bg.rgb
		+ accent_color.rgb * (pulse_boost * horizon_glow + grid_shimmer)
		+ perfect_tint * lane_flash
		+ drop_ring_color * drop_shockwave;

	float luma = dot(raw_rgb, vec3(0.299, 0.587, 0.114));
	float saturation_boost = clamp(
		1.0 + (0.14 * energy_level) + (0.14 * bass_energy) + (0.10 * drop_active),
		1.0,
		1.35
	);
	vec3 saturated_rgb = mix(vec3(luma), raw_rgb, saturation_boost);

	// Subtle border-emanating light-blue neon wave blur (gameplay-only, lateral <= 0.044, top/bottom <= 0.028, opacity <= 0.52)
	float inv_aspect = 1.0 / max(aspect_ratio, 0.001);
	vec2 centered_p = vec2(UV.x - 0.5, (UV.y - 0.5) * inv_aspect);
	float angle = atan(centered_p.y, centered_p.x);

	float dist_x = min(UV.x, 1.0 - UV.x);
	float dist_y = min(UV.y, 1.0 - UV.y) * inv_aspect;
	float edge_dist = min(dist_x, dist_y);
	float lateral_weight = smoothstep(-0.025, 0.025, dist_y - dist_x);

	// Integer angular harmonics around center (zero diagonal corner seams)
	float h3 = sin((3.0 * angle) - (TIME * 1.35)) * 0.5 + 0.5;
	float h5 = sin((5.0 * angle) + (TIME * 2.10)) * 0.5 + 0.5;
	float h8 = sin((8.0 * angle) - (TIME * 3.25)) * 0.5 + 0.5;
	float h11 = sin((11.0 * angle) + (TIME * 4.40)) * 0.5 + 0.5;

	float idle_crest = (h3 * 0.48) + (h5 * 0.34) + (h8 * 0.18);
	float spectral_crest = (pow(h3, 1.55) * bass_energy * 0.0075)
		+ (pow(h5, 1.65) * mid_energy * 0.0055)
		+ ((pow(h8, 1.85) * 0.65 + pow(h11, 2.1) * 0.35) * high_energy * 0.0035);
	float raw_crest = clamp((idle_crest * 0.45) + (h3 * 0.30) + (h5 * 0.25), 0.0, 1.0);
	float lateral_crest = pow(raw_crest, 1.85);
	float crest_shape = mix(raw_crest, lateral_crest, lateral_weight);

	// Accented crest-valley undulation on lateral edges (<= 0.044) while top/bottom stay contained (<= 0.028)
	float edge_amp_scale = mix(1.0, lateral_wave_boost, lateral_weight);
	float edge_reach_cap = mix(0.028, 0.044, lateral_weight);
	float base_reach = mix(0.006, 0.005, lateral_weight) + (crest_shape * mix(0.004, 0.010, lateral_weight));
	float beat_expand = (edge_glow_intensity * (0.003 + (0.010 * crest_shape)))
		+ (edge_drop_boost * (0.004 + (0.011 * crest_shape)));
	float wave_reach = clamp(
		base_reach + (((spectral_crest * wave_amplitude) + beat_expand) * edge_amp_scale),
		0.005,
		edge_reach_cap
	);

	// Soft filled blur gradient from physical edge (edge_dist = 0.0) without saturating to solid white
	float fill_blur = pow(smoothstep(wave_reach, 0.0, edge_dist), 1.45);
	float bezel_core = pow(smoothstep(wave_reach * 0.40, 0.0, edge_dist), 2.1);

	vec3 neon_blue = mix(edge_primary_color.rgb, edge_drop_color.rgb, clamp(edge_drop_boost * 0.35, 0.0, 1.0));
	vec3 core_ice_blue = mix(neon_blue, vec3(0.72, 0.94, 1.00), 0.45);

	float raw_opacity = wave_blur_intensity + (edge_glow_intensity * 0.16) + (edge_drop_boost * 0.22);
	float max_opacity = clamp(raw_opacity, 0.0, 0.42) * perimeter_wave_enabled * drop_active;
	float edge_alpha = clamp((fill_blur * 0.82 + bezel_core * 0.18) * max_opacity, 0.0, 0.42);

	vec3 wave_tint = mix(neon_blue, core_ice_blue, bezel_core * 0.55);
	vec3 final_rgb = clamp(
		mix(saturated_rgb, max(saturated_rgb, wave_tint), edge_alpha) + (wave_tint * edge_alpha * 0.22),
		vec3(0.0),
		vec3(1.0)
	);
	COLOR = vec4(final_rgb, 1.0);
}
