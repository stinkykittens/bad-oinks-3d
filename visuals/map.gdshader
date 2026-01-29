shader_type spatial;

uniform sampler2D ground_texture : repeat_enable;
uniform sampler2D wall_texture : repeat_enable;
uniform sampler2D ceiling_texture : repeat_enable;

void fragment() {
	vec4 vertex = INV_VIEW_MATRIX * vec4(VERTEX, 1);
	vec3 normal = normalize(INV_VIEW_MATRIX * vec4(NORMAL, 0)).xyz;
	
	float seperation = dot(normal, vec3(0, 1, 0));
	
	vec3 wall = texture(wall_texture, vec2(mix(vertex.x, vertex.z, normal.x), vertex.y)).rgb;
	vec3 ground = texture(ground_texture, vertex.xz).rgb;
	vec3 ceiling = texture(ceiling_texture, vertex.xz).rgb;
	
	float wall_mix = 1.0 - abs(seperation);
	float ground_mix = max(seperation, 0.0);
	float ceiling_mix = max(0.0 - seperation, 0.0);
	
	ALBEDO = wall * wall_mix + ground * ground_mix + ceiling * ceiling_mix;
}

