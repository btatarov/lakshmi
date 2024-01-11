package renderer

import "core:math/rand"
import "vendor:OpenGL"

VBO, VAO     : u32
Program      : u32

Triangle : [3 * 3] f32 = {
    -0.5, -0.5, 0.0,
     0.5, -0.5, 0.0,
     0.0,  0.5, 0.0,
}

Init :: proc(width, height : i32) {
    RefreshViewport(width, height)

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
    vertex_shader := string(#load("../../temp/vertex.glsl"))
    fragment_shader := string(#load("../../temp/fragment.glsl"))
    Program, ok = OpenGL.load_shaders_source(vertex_shader, fragment_shader)
    assert(ok, "Failed to load and compile shaders.")

    OpenGL.UseProgram(Program)
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
