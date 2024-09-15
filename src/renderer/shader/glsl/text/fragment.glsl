#version 410 core

in vec4 vertex_color;
in vec2 uv;

uniform sampler2D u_texture;

out vec4 fragment_color;

void main() {
    fragment_color = vec4(vertex_color.xyz, texture(u_texture, uv).r);
}
