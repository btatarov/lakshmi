package renderer

import "core:fmt"
import "core:image/png"

import "vendor:OpenGL"

import IndexBuffer "buffers/index"
import VertexBuffer "buffers/vertex"
import VertexArray "buffers/array"
import Camera "camera"
import Shader "shader"
import Texture "texture"

@private index_buffer   : IndexBuffer.IndexBuffer
@private vertex_buffer  : VertexBuffer.VertexBuffer
@private vertex_array   : VertexArray.VertexArray
@private main_shader    : Shader.Shader
@private texture        : Texture.Texture

@private quad : [4 * 9] f32 = {
    // positions        // colors               // uv coords
     0.5,  0.5, 0.0,    1.0, 0.0, 0.0, 1.0,     1.0, 0.0, // top right
     0.5, -0.5, 0.0,    0.0, 1.0, 0.0, 1.0,     1.0, 1.0, // bottom right
    -0.5, -0.5, 0.0,    1.0, 0.0, 0.0, 1.0,     0.0, 1.0, // bottom left
    -0.5,  0.5, 0.0,    0.0, 0.0, 1.0, 1.0,     0.0, 0.0, // top left
}
@private indecies : [2 * 3] u32 = {
    0, 1, 3,
    1, 2, 3,
}

Init :: proc(width, height : i32) {
    RefreshViewport(width, height)

    OpenGL.BlendFunc(OpenGL.SRC_ALPHA, OpenGL.ONE_MINUS_SRC_ALPHA)
    OpenGL.Enable(OpenGL.BLEND)

    // Testing: wireframe mode
    // OpenGL.PolygonMode(OpenGL.FRONT_AND_BACK, OpenGL.LINE)

    // camera
    ratio := f32(width) / f32(height)
    camera := Camera.Init(-ratio, ratio, -1, 1)
    camera->set_position({0.5, 0.5, 0})
    camera->set_rotation(30)

    // shader
    main_shader = Shader.Init()
    main_shader->apply_projection(camera->get_vp_matrix())

    // texture
    texture = Texture.Init("test/lakshmi.png")

    // buffers
    vertex_buffer = VertexBuffer.Init(quad[:], size_of(quad))
    vertex_array = VertexArray.Init()
    index_buffer = IndexBuffer.Init(indecies[:], len(indecies))
}

Destroy :: proc() {
    Shader.Destroy(&main_shader)

    Texture.Destroy(&texture)

    VertexBuffer.Destroy(&vertex_buffer)
    VertexArray.Destroy(&vertex_array)
    IndexBuffer.Destroy(&index_buffer)
}

RefreshViewport :: proc(width, height : i32) {
    OpenGL.Viewport(0, 0, width, height)
}

Render :: proc() {
    OpenGL.ClearColor(0.3, 0.3, 0.3, 1.0)
    OpenGL.Clear(OpenGL.COLOR_BUFFER_BIT | OpenGL.DEPTH_BUFFER_BIT)

    OpenGL.BindTexture(OpenGL.TEXTURE_2D, texture.id)
    OpenGL.BindVertexArray(vertex_array.id)
    OpenGL.DrawElements(OpenGL.TRIANGLES, index_buffer.count, OpenGL.UNSIGNED_INT, nil)
}
