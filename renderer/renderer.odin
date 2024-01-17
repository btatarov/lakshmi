package renderer

import "core:fmt"
import "core:math/rand"
import "vendor:OpenGL"

import IndexBuffer "buffers/index"
import VertexBuffer "buffers/vertex"
import Camera "camera"
import Shader "shader"

@private index_buffer   : IndexBuffer.IndexBuffer
@private vertex_buffer  : VertexBuffer.VertexBuffer
@private main_shader    : Shader.Shader

@private VAO            : u32

@private triangle : [3 * 3] f32 = {
    -0.5, -0.5, 0.0,
     0.5, -0.5, 0.0,
     0.0,  0.5, 0.0,
}
@private indecies : [3] u32 = {
    0, 1, 2,
}

Init :: proc(width, height : i32) {
    RefreshViewport(width, height)

    // camera
    camera := Camera.Init(- (4 / 3), 4 / 3, -1, 1)
    camera->set_position({0.5, 0.5, 0})
    camera->set_rotation(30)

    // buffers
    OpenGL.GenVertexArrays(1, &VAO)
    OpenGL.BindVertexArray(VAO)

    vertex_buffer = VertexBuffer.Init(&triangle, size_of(triangle))
    index_buffer = IndexBuffer.Init(&indecies, size_of(indecies))

    OpenGL.EnableVertexAttribArray(0)
    OpenGL.VertexAttribPointer(0, 3, OpenGL.FLOAT, OpenGL.FALSE, 3 * size_of(f32), 0)

    // shader
    main_shader = Shader.Init()

    // apply camera projection matrix
    vp_matrix := camera->get_vp_matrix()
    uniform_location := OpenGL.GetUniformLocation(main_shader.program, "u_projection")
    OpenGL.UniformMatrix4fv(uniform_location, 1, false, &vp_matrix[0][0])
}

Destroy :: proc() {
    Shader.Destroy(&main_shader)

    VertexBuffer.Destroy(&vertex_buffer)
    IndexBuffer.Destroy(&index_buffer)

    OpenGL.DeleteBuffers(1, &VAO)
    OpenGL.DeleteVertexArrays(1, &VAO)
}

RefreshViewport :: proc "contextless" (width, height : i32) {
    OpenGL.Viewport(0, 0, width, height)
}

Render :: proc() {
    OpenGL.ClearColor(rand.float32(), rand.float32(), rand.float32(), 1.0)
    OpenGL.Clear(OpenGL.COLOR_BUFFER_BIT | OpenGL.DEPTH_BUFFER_BIT)

    OpenGL.BindVertexArray(VAO)
    OpenGL.DrawElements(OpenGL.TRIANGLES, 3, OpenGL.UNSIGNED_INT, nil)
}
