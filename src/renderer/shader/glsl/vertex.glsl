#version 330 core

layout (location = 0) in vec3 a_position;
layout (location = 1) in vec4 a_color;
layout (location = 2) in vec2 a_uv;

uniform mat4 u_projection;

out vec4 vertex_color;
out vec2 uv;

void main() {
    gl_Position = u_projection * vec4(a_position, 1.0);
    vertex_color = a_color;
    uv = a_uv;
}
