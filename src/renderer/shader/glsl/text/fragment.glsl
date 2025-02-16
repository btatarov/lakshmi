#version 410 core

in vec4 vertex_color;
in vec2 uv;

uniform sampler2D u_texture;

out vec4 fragment_color;

void main() {
    fragment_color = vec4(vertex_color.rgb, texture(u_texture, uv).r);
    fragment_color.r = mix(0, 1, fragment_color.r * vertex_color.a);
    fragment_color.g = mix(0, 1, fragment_color.g * vertex_color.a);
    fragment_color.b = mix(0, 1, fragment_color.b * vertex_color.a);
    fragment_color.a = mix(0, 1, fragment_color.a * vertex_color.a);
}
