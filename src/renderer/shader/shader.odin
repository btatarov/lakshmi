package renderer_shader

import "core:math/linalg"

import gl "vendor:OpenGL"

Shader :: struct {
    program: u32,

    apply_projection:   proc(shader: ^Shader, projection: ^linalg.Matrix4f32),
    bind:               proc(shader: ^Shader),
    unbind:             proc(_: ^Shader),
}

Init :: proc() -> (shader: Shader) {
    ok : bool
    vertex_shader := string(#load("glsl/vertex.glsl"))
    fragment_shader := string(#load("glsl/fragment.glsl"))
    shader.program, ok = gl.load_shaders_source(vertex_shader, fragment_shader)
    assert(ok, "Failed to load and compile shaders.")
    gl.UseProgram(shader.program)

    shader.apply_projection = shader_apply_projection
    shader.bind             = shader_bind
    shader.unbind           = shader_unbind

    return
}

Destroy :: proc(shader: ^Shader) {
    gl.DeleteProgram(shader.program)
}

shader_apply_projection :: proc(shader: ^Shader, projection: ^linalg.Matrix4f32) {
    uniform_location := gl.GetUniformLocation(shader.program, "u_projection")
    gl.UniformMatrix4fv(uniform_location, 1, false, &projection[0][0])
}

shader_bind :: proc(shader: ^Shader) {
    gl.UseProgram(shader.program)
}

shader_unbind :: proc(_: ^Shader) {
    gl.UseProgram(0)
}
