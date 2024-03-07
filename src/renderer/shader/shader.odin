package shader

import "core:math/linalg"

import "vendor:OpenGL"

import Texture "../texture"

Shader :: struct {
    program: u32,

    apply_projection:   proc(shader: ^Shader, projection: ^linalg.Matrix4f32),
    apply_textures:     proc(shader: ^Shader),
    bind:               proc(shader: ^Shader),
    unbind:             proc(_: ^Shader),
}

Init :: proc() -> (shader: Shader) {
    ok : bool
    vertex_shader := string(#load("glsl/vertex.glsl"))
    fragment_shader := string(#load("glsl/fragment.glsl"))
    shader.program, ok = OpenGL.load_shaders_source(vertex_shader, fragment_shader)
    assert(ok, "Failed to load and compile shaders.")
    OpenGL.UseProgram(shader.program)

    shader.apply_projection = shader_apply_projection
    shader.apply_textures   = shader_apply_textures
    shader.bind             = shader_bind
    shader.unbind           = shader_unbind

    return
}

Destroy :: proc(shader: ^Shader) {
    OpenGL.DeleteProgram(shader.program)
}

shader_apply_projection :: proc(shader: ^Shader, projection: ^linalg.Matrix4f32) {
    uniform_location := OpenGL.GetUniformLocation(shader.program, "u_projection")
    OpenGL.UniformMatrix4fv(uniform_location, 1, false, &projection[0][0])
}

shader_apply_textures :: proc(shader: ^Shader) {
    textures := Texture.GetCache()
    samplers := make([]i32, len(textures) + 1)
    defer delete(samplers)

    // 0 is reserved for empty texture
    OpenGL.ActiveTexture(OpenGL.TEXTURE0)
    OpenGL.BindTexture(OpenGL.TEXTURE_2D, 0)

    for _, &texture in textures {
        OpenGL.ActiveTexture(OpenGL.TEXTURE0 + texture.slot)
        OpenGL.BindTexture(OpenGL.TEXTURE_2D, texture.id)
        samplers[texture.slot] = i32(texture.id)
    }

    uniform_location := OpenGL.GetUniformLocation(shader.program, "u_textures")
    OpenGL.Uniform1iv(uniform_location, i32(len(textures) + 1), &samplers[0])
}

shader_bind :: proc(shader: ^Shader) {
    OpenGL.UseProgram(shader.program)
}

shader_unbind :: proc(_: ^Shader) {
    OpenGL.UseProgram(0)
}
