package shader

import "vendor:OpenGL"

Shader :: struct {
    program : u32,
}

Init :: proc() -> (shader: Shader) {
    ok : bool
    vertex_shader := string(#load("glsl/vertex.glsl"))
    fragment_shader := string(#load("glsl/fragment.glsl"))
    shader.program, ok = OpenGL.load_shaders_source(vertex_shader, fragment_shader)
    assert(ok, "Failed to load and compile shaders.")

    OpenGL.UseProgram(shader.program)

    return
}

Destroy :: proc(shader: ^Shader) {
    OpenGL.DeleteProgram(shader.program)
}
