package renderer

import "core:fmt"
import "core:math/rand"
import "vendor:OpenGL"

import Camera "camera"
import Shader "shader"

// TODO: struct (OOP)
VAO, VBO, EBO   : u32
main_shader     : Shader.Shader

triangle : [3 * 3] f32 = {
    -0.5, -0.5, 0.0,
     0.5, -0.5, 0.0,
     0.0,  0.5, 0.0,
}

indecies : [3] u32 = {
    0, 1, 2,
}

Init :: proc(width, height : i32) {
    RefreshViewport(width, height)

    // camera
    camera := Camera.Init(- (4 / 3), 4 / 3, -1, 1)
    camera->set_position({0.5, 0.5, 0})
    camera->set_rotation(30)

    // opengl setup
    OpenGL.GenVertexArrays(1, &VAO)
    OpenGL.BindVertexArray(VAO)

    OpenGL.GenBuffers(1, &VBO)
    OpenGL.BindBuffer(OpenGL.ARRAY_BUFFER, VBO)

    OpenGL.GenBuffers(1, &EBO)
    OpenGL.BindBuffer(OpenGL.ELEMENT_ARRAY_BUFFER, EBO)

    // vertex data
    OpenGL.BufferData(OpenGL.ARRAY_BUFFER, size_of(triangle), &triangle, OpenGL.STATIC_DRAW)
    OpenGL.BufferData(OpenGL.ELEMENT_ARRAY_BUFFER, size_of(indecies), &indecies, OpenGL.STATIC_DRAW)

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

    OpenGL.DeleteBuffers(1, &VBO)
    OpenGL.DeleteBuffers(1, &EBO)
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
