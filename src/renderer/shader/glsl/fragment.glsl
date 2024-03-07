#version 410 core

in vec4 vertex_color;
in vec2 uv;
in float texture_index;

uniform sampler2D u_textures[32];

out vec4 fragment_color;

void main() {
    int index = int(texture_index + 0.5);
    fragment_color = texture(u_textures[index], uv) * vertex_color;
}
