package renderer

import "core:fmt"
import "core:math/rand"
import "vendor:OpenGL"

import Camera "camera"

VBO, VAO     : u32
Program      : u32

Triangle : [3 * 3] f32 = {
    -0.5, -0.5, 0.0,
     0.5, -0.5, 0.0,
     0.0,  0.5, 0.0,
}

Init :: proc(width, height : i32) {
    RefreshViewport(width, height)

    // opengl setup
    OpenGL.GenBuffers(1, &VBO)
    OpenGL.BindBuffer(OpenGL.ARRAY_BUFFER, VBO)

    OpenGL.GenVertexArrays(1, &VAO)
    OpenGL.BindVertexArray(VAO)
    OpenGL.BindBuffer(OpenGL.ARRAY_BUFFER, VBO)

    OpenGL.BufferData(OpenGL.ARRAY_BUFFER, size_of(Triangle), &Triangle, OpenGL.STATIC_DRAW)
    OpenGL.VertexAttribPointer(0, 3, OpenGL.FLOAT, false, 3 * size_of(f32), 0)
    OpenGL.EnableVertexAttribArray(0)

    // shaders
    ok : bool
    vertex_shader := string(#load("shaders/vertex.glsl"))
    fragment_shader := string(#load("shaders/fragment.glsl"))
    Program, ok = OpenGL.load_shaders_source(vertex_shader, fragment_shader)
    assert(ok, "Failed to load and compile shaders.")
    OpenGL.UseProgram(Program)

    // camera
    camera := Camera.Init(- (4 / 3), 4 / 3, -1, 1)
    camera->set_position({0.5, 0.5, 0})
    camera->set_rotation(30)

    // apply projection matrix
    vp_matrix := camera->get_vp_matrix()
    uniform_location := OpenGL.GetUniformLocation(Program, "u_projection")
    OpenGL.UniformMatrix4fv(uniform_location, 1, false, &vp_matrix[0][0])
}

Render :: proc() {
    OpenGL.ClearColor(rand.float32(), rand.float32(), rand.float32(), 1.0)
    OpenGL.Clear(OpenGL.COLOR_BUFFER_BIT | OpenGL.DEPTH_BUFFER_BIT)
    OpenGL.DrawArrays(OpenGL.TRIANGLES, 0, 3)
}

Destroy :: proc() {
    OpenGL.DeleteBuffers(1, &VBO)
    OpenGL.DeleteBuffers(1, &VAO)
    OpenGL.DeleteVertexArrays(1, &VAO)
    OpenGL.DeleteProgram(Program)
}

RefreshViewport :: proc "contextless" (width, height : i32) {
    OpenGL.Viewport(0, 0, width, height)
}
