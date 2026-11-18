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

void fragment() {
	float zoom_scale = 1.0 / (1.0 + (zoom_bounce * 0.14));
	vec2 uv = clamp((UV - vec2(0.5)) * zoom_scale + vec2(0.5), vec2(0.0), vec2(1.0));

	float tier_factor = float(intensity_tier) / 3.0;
	vec3 boosted_bottom = base_color_bottom.rgb + (accent_color.rgb * (0.12 * bass_energy + 0.09 * mid_energy));
	vec4 bg = mix(base_color_top, vec4(boosted_bottom, 1.0), uv.y);

	float horizon_glow = exp(-abs(uv.y - 0.84) * (10.0 - tier_factor * 4.0));
	float pulse_boost = (beat_pulse * (0.18 + 0.22 * energy_level + 0.15 * tier_factor)) + (bass_energy * 0.20);

	float wave_speed = 1.5 + (tier_factor * 2.5) + (mid_energy * 1.4);
	float wave = sin((uv.y * 18.0) - (TIME * wave_speed)) * 0.5 + 0.5;
	float harmonic = sin((uv.x * 12.0) + (uv.y * 28.0) - (TIME * 3.2)) * 0.5 + 0.5;
	float grid_shimmer = (wave * horizon_glow * (0.10 + 0.25 * energy_level + 0.18 * mid_energy))
		+ (harmonic * horizon_glow * high_energy * 0.16);

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
	float lane_mask = exp(-abs(uv.x - lane_center_x) * 26.0);
	float lane_flash = lane_energy * lane_mask * smoothstep(0.15, 0.95, uv.y) * 0.42;

	vec3 final_rgb = bg.rgb + accent_color.rgb * (pulse_boost * horizon_glow + grid_shimmer + lane_flash);
	COLOR = vec4(clamp(final_rgb, vec3(0.0), vec3(1.0)), 1.0);
}
