#version 330 core

in vec3 vertex_color;
in vec2 uv;

uniform sampler2D u_texture;

out vec4 fragment_color;

void main() {
    fragment_color = texture(u_texture, uv);
}
