shader_type spatial;
render_mode cull_disabled;

uniform vec3 color : source_color;
uniform vec3 color2 : source_color;
uniform sampler2D noise;
uniform float noiseScale = 20.0;

uniform vec2 scroll_speed = vec2(0.5, 0.2);
uniform float sway_strength = 0.2;
uniform float sway_frequency = 1.0;

uniform vec3 player_position;
uniform float deform_radius = 2.0;
uniform float deform_strength = 1;
uniform float grass_height = 0.5;

varying vec3 worldPos;

void vertex() {
	worldPos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

	//playerInteration
	// Calculate the 2D vector from the player to the vertex (ignoring height)
	vec2 playerToVertex2D = worldPos.xz - player_position.xz;

	// Calculate the distance and normalize the direction
	float dist = length(playerToVertex2D);
	vec2 deform_direction_2D = normalize(playerToVertex2D);

	// Determine the deformation strength based on distance
	float deform_factor = smoothstep(deform_radius, 0.0, dist);

	// Create a factor that is 0 at the base (y=0) and 1 at the top (y=grass_height)
	// Clamp the value to ensure it stays between 0.0 and 1.0
	float height_factor = clamp(VERTEX.y / grass_height, 0.0, 1.0);

	// Combine the distance-based factor with the height-based factor
	float final_deform_factor = deform_factor * height_factor;

	// Create the 3D deformation vector, with no change in the Y-axis
	vec3 deform_vector = vec3(deform_direction_2D.x, 0.0, deform_direction_2D.y) * final_deform_factor * deform_strength;

	// Push the vertex away from the player in the XZ plane
	VERTEX += deform_vector;

	 vec2 windUV = worldPos.xz / noiseScale + scroll_speed * TIME;
    float wind = texture(noise, windUV).r;

    // Add sine wave motion
    float sineWave = sin(TIME * sway_frequency + worldPos.x * 0.1 + worldPos.z * 0.1);

    float sway = ((wind - 0.5) * 2.0 + sineWave * 0.5) * sway_strength;
    VERTEX.x += sway * height_factor;
    VERTEX.z += sway * height_factor;
}

void fragment() {
	vec2 windUV = worldPos.xz / noiseScale;
	windUV += scroll_speed * TIME;

    // Scroll the noise sample using uv instead of static worldPos
    vec3 noiseLevel = texture(noise, windUV).rgb;

    // Blend colors based on UV and noise

    ALBEDO = mix(color, color2, UV.y) * mix(color, color2, noiseLevel.r);

	 if (!FRONT_FACING) {
        NORMAL = -NORMAL;
    }
}


