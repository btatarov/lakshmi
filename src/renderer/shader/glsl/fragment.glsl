#version 410 core

in vec4 vertex_color;
in vec2 uv;
in float texture_index;

uniform sampler2D u_textures[16];

out vec4 fragment_color;

void main() {
    // TODO: temporary fix for macos
    if (texture_index == 0) {
        fragment_color = vertex_color;
    }
    else if (texture_index == 1) {
        fragment_color = texture(u_textures[1], uv) * vertex_color;
    }
    else if (texture_index == 2) {
        fragment_color = texture(u_textures[2], uv) * vertex_color;
    }
    else if (texture_index == 3) {
        fragment_color = texture(u_textures[3], uv) * vertex_color;
    }
    else if (texture_index == 4) {
        fragment_color = texture(u_textures[4], uv) * vertex_color;
    }
    else if (texture_index == 5) {
        fragment_color = texture(u_textures[5], uv) * vertex_color;
    }
    else if (texture_index == 6) {
        fragment_color = texture(u_textures[6], uv) * vertex_color;
    }
    else if (texture_index == 7) {
        fragment_color = texture(u_textures[7], uv) * vertex_color;
    }
    else if (texture_index == 8) {
        fragment_color = texture(u_textures[8], uv) * vertex_color;
    }
    else if (texture_index == 9) {
        fragment_color = texture(u_textures[9], uv) * vertex_color;
    }
    else if (texture_index == 10) {
        fragment_color = texture(u_textures[10], uv) * vertex_color;
    }
    else if (texture_index == 11) {
        fragment_color = texture(u_textures[11], uv) * vertex_color;
    }
    else if (texture_index == 12) {
        fragment_color = texture(u_textures[12], uv) * vertex_color;
    }
    else if (texture_index == 13) {
        fragment_color = texture(u_textures[13], uv) * vertex_color;
    }
    else if (texture_index == 14) {
        fragment_color = texture(u_textures[14], uv) * vertex_color;
    }
    else if (texture_index == 15) {
        fragment_color = texture(u_textures[15], uv) * vertex_color;
    }
}
