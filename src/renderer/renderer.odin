package renderer

import "core:fmt"
import "core:image/png"

import "vendor:OpenGL"

import IndexBuffer "buffers/index"
import VertexBuffer "buffers/vertex"
import Camera "camera"
import Shader "shader"

@private index_buffer   : IndexBuffer.IndexBuffer
@private vertex_buffer  : VertexBuffer.VertexBuffer
@private main_shader    : Shader.Shader
@private texture        : u32

@private quad : [4 * 9] f32 = {
    // positions        // colors               // uv coords
     0.5,  0.5, 0.0,    1.0, 0.0, 0.0, 1.0,     1.0, 1.0, // top right
     0.5, -0.5, 0.0,    0.0, 1.0, 0.0, 1.0,     1.0, 0.0, // bottom right
    -0.5, -0.5, 0.0,    1.0, 0.0, 0.0, 1.0,     0.0, 0.0, // bottom left
    -0.5,  0.5, 0.0,    0.0, 0.0, 1.0, 1.0,     0.0, 1.0, // top left
}
@private indecies : [2 * 3] u32 = {
    0, 1, 3,
    1, 2, 3,
}

Init :: proc(width, height : i32) {
    RefreshViewport(width, height)

    // Testing: wireframe mode
    // OpenGL.PolygonMode(OpenGL.FRONT_AND_BACK, OpenGL.LINE)

    // camera
    ratio := f32(width) / f32(height)
    camera := Camera.Init(-ratio, ratio, -1, 1)
    camera->set_position({0.5, 0.5, 0})
    camera->set_rotation(30)

    // shader
    main_shader = Shader.Init()

    // texture
    sprite, err := png.load_from_file("test/lakshmi.png")
    assert(err == nil , "Failed to load texture")
    defer png.destroy(sprite)

    OpenGL.GenTextures(1, &texture)
    OpenGL.BindTexture(OpenGL.TEXTURE_2D, texture)
    OpenGL.TexParameteri(OpenGL.TEXTURE_2D, OpenGL.TEXTURE_WRAP_S, OpenGL.CLAMP_TO_EDGE)
    OpenGL.TexParameteri(OpenGL.TEXTURE_2D, OpenGL.TEXTURE_WRAP_T, OpenGL.CLAMP_TO_EDGE)
    OpenGL.TexParameteri(OpenGL.TEXTURE_2D, OpenGL.TEXTURE_MIN_FILTER, OpenGL.LINEAR)
    OpenGL.TexParameteri(OpenGL.TEXTURE_2D, OpenGL.TEXTURE_MAG_FILTER, OpenGL.NEAREST)
    OpenGL.TexImage2D(OpenGL.TEXTURE_2D, 0, OpenGL.RGBA, i32(sprite.width), i32(sprite.height), 0, OpenGL.RGBA, OpenGL.UNSIGNED_BYTE, raw_data(sprite.pixels.buf))
    OpenGL.GenerateMipmap(OpenGL.TEXTURE_2D)

    // buffers
    vertex_buffer = VertexBuffer.Init(quad[:], size_of(quad))
    index_buffer = IndexBuffer.Init(indecies[:], len(indecies))

    // apply camera projection matrix
    vp_matrix := camera->get_vp_matrix()
    uniform_location := OpenGL.GetUniformLocation(main_shader.program, "u_projection")
    OpenGL.UniformMatrix4fv(uniform_location, 1, false, &vp_matrix[0][0])
}

Destroy :: proc() {
    Shader.Destroy(&main_shader)

    VertexBuffer.Destroy(&vertex_buffer)
    IndexBuffer.Destroy(&index_buffer)

    OpenGL.DeleteBuffers(1, &vertex_buffer.VAO)
    OpenGL.DeleteVertexArrays(1, &vertex_buffer.VAO)
}

RefreshViewport :: proc(width, height : i32) {
    OpenGL.Viewport(0, 0, width, height)
}

Render :: proc() {
    OpenGL.ClearColor(0.3, 0.3, 0.3, 1.0)
    OpenGL.Clear(OpenGL.COLOR_BUFFER_BIT | OpenGL.DEPTH_BUFFER_BIT)

    OpenGL.BindTexture(OpenGL.TEXTURE_2D, texture)
    OpenGL.BindVertexArray(vertex_buffer.VAO)
    OpenGL.DrawElements(OpenGL.TRIANGLES, index_buffer.count, OpenGL.UNSIGNED_INT, nil)
}
