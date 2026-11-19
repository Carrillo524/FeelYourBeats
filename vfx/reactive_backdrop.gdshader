shader_type canvas_item;

uniform vec4 base_color_top : source_color = vec4(0.04, 0.05, 0.12, 1.0);
uniform vec4 base_color_bottom : source_color = vec4(0.09, 0.03, 0.18, 1.0);
uniform vec4 accent_color : source_color = vec4(0.20, 0.85, 1.00, 1.0);
uniform float beat_pulse : hint_range(0.0, 1.0) = 0.0;
uniform float energy_level : hint_range(0.0, 1.0) = 0.25;
uniform int intensity_tier : hint_range(0, 3) = 0;
uniform vec4 lane_hit_energies = vec4(0.0, 0.0, 0.0, 0.0);
uniform float bass_energy : hint_range(0.0, 1.0) = 0.0;
uniform float mid_energy : hint_range(0.0, 1.0) = 0.0;
uniform float high_energy : hint_range(0.0, 1.0) = 0.0;
uniform float zoom_bounce : hint_range(0.0, 0.25) = 0.0;
uniform vec2 shake_offset = vec2(0.0, 0.0);
uniform float aspect_ratio : hint_range(0.25, 4.0) = 0.5625;
uniform float edge_glow_intensity : hint_range(0.0, 1.5) = 0.28;
uniform float edge_glow_width : hint_range(0.01, 0.45) = 0.11;
uniform float edge_drop_boost : hint_range(0.0, 1.0) = 0.0;
uniform vec4 edge_primary_color : source_color = vec4(0.16, 0.88, 1.00, 1.0);
uniform vec4 edge_drop_color : source_color = vec4(1.00, 0.26, 0.86, 1.0);

void fragment() {
	float zoom_scale = 1.0 / (1.0 + (zoom_bounce * 0.16));
	vec2 uv = clamp(((UV - vec2(0.5)) * zoom_scale) + vec2(0.5) + shake_offset, vec2(0.0), vec2(1.0));

	float tier_factor = float(intensity_tier) / 3.0;
	float drop_active = step(2.0, float(intensity_tier));

	vec3 drop_tint = vec3(0.95, 0.22, 0.78) * (drop_active * (0.14 + 0.18 * bass_energy));
	vec3 boosted_bottom = base_color_bottom.rgb + (accent_color.rgb * (0.14 * bass_energy + 0.10 * mid_energy)) + drop_tint;
	vec4 bg = mix(base_color_top, vec4(boosted_bottom, 1.0), uv.y);

	float horizon_glow = exp(-abs(uv.y - 0.84) * (9.5 - tier_factor * 4.2));
	float pulse_boost = (beat_pulse * (0.20 + 0.24 * energy_level + 0.18 * tier_factor)) + (bass_energy * 0.24);

	float wave_speed = 1.6 + (tier_factor * 2.8) + (mid_energy * 1.6);
	float wave = sin((uv.y * 18.0) - (TIME * wave_speed)) * 0.5 + 0.5;
	float harmonic = sin((uv.x * 12.0) + (uv.y * 28.0) - (TIME * 3.4)) * 0.5 + 0.5;
	float grid_shimmer = (wave * horizon_glow * (0.10 + 0.26 * energy_level + 0.20 * mid_energy))
		+ (harmonic * horizon_glow * high_energy * 0.18);

	vec2 shock_center = vec2(0.5, 0.84);
	float radial_dist = length((uv - shock_center) * vec2(1.0, 1.65));
	float ring_wave = sin((radial_dist * 24.0) - (TIME * (6.5 + bass_energy * 4.0))) * 0.5 + 0.5;
	float shock_envelope = exp(-radial_dist * 3.2) * (0.35 + 0.65 * max(beat_pulse, bass_energy));
	float drop_shockwave = drop_active * pow(ring_wave, 3.0) * shock_envelope * (0.28 + 0.22 * tier_factor);

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
	float saturation_boost = 1.0 + (0.32 * energy_level) + (0.42 * bass_energy) + (0.22 * drop_active);
	vec3 saturated_rgb = mix(vec3(luma), raw_rgb, saturation_boost);

	// Aspect-ratio-corrected perimeter neon blur halo (center remains 100% clean)
	float dist_x = min(UV.x, 1.0 - UV.x);
	float dist_y = min(UV.y, 1.0 - UV.y) / max(aspect_ratio, 0.001);
	float edge_dist = min(dist_x, dist_y);
	float safe_width = max(edge_glow_width, 0.02);

	float outer_norm = clamp(edge_dist / safe_width, 0.0, 1.0);
	float outer_blur = pow(1.0 - outer_norm, 2.6) * smoothstep(1.0, 0.0, outer_norm);

	float mid_norm = clamp(edge_dist / (safe_width * 0.48), 0.0, 1.0);
	float mid_halo = exp(-mid_norm * 3.2) * (1.0 - smoothstep(0.75, 1.0, mid_norm));

	float rim_norm = clamp(edge_dist / (safe_width * 0.14), 0.0, 1.0);
	float hot_rim = pow(1.0 - rim_norm, 2.2) * (1.0 - smoothstep(0.85, 1.0, rim_norm));

	float perim_wave = sin((UV.x * 10.0 + UV.y * 16.0) - (TIME * (2.6 + edge_drop_boost * 4.2))) * 0.5 + 0.5;
	float wave_mod = mix(0.92, 1.08, perim_wave * (0.35 + 0.65 * edge_drop_boost));

	vec3 drop_gold = vec3(1.0, 0.80, 0.24);
	vec3 drop_mix_color = mix(edge_drop_color.rgb, drop_gold, perim_wave * 0.38 * edge_drop_boost);
	vec3 halo_color = mix(edge_primary_color.rgb, drop_mix_color, clamp(edge_drop_boost * 0.92, 0.0, 1.0));
	vec3 core_white = mix(halo_color, vec3(1.0, 0.98, 1.0), 0.55 + 0.30 * edge_drop_boost);

	float edge_energy = (outer_blur * 0.58 + mid_halo * 0.52) * edge_glow_intensity * wave_mod;
	float rim_energy = hot_rim * edge_glow_intensity * (0.45 + 0.55 * edge_drop_boost);
	vec3 edge_halo_rgb = (halo_color * edge_energy) + (core_white * rim_energy);

	vec3 final_rgb = clamp(saturated_rgb + edge_halo_rgb, vec3(0.0), vec3(1.0));
	COLOR = vec4(final_rgb, 1.0);
}
