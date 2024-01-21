package vertex

import "vendor:OpenGL"

VertexBuffer :: struct {
    VAO, VBO    : u32,
}

Init :: proc(vertices: []f32, size: int) -> (buffer : VertexBuffer) {
    OpenGL.GenBuffers(1, &buffer.VBO)
    OpenGL.BindBuffer(OpenGL.ARRAY_BUFFER, buffer.VBO)
    OpenGL.BufferData(OpenGL.ARRAY_BUFFER, size, &vertices[0], OpenGL.STATIC_DRAW)

    OpenGL.GenVertexArrays(1, &buffer.VAO)
    OpenGL.BindVertexArray(buffer.VAO)
    OpenGL.EnableVertexAttribArray(0)
    OpenGL.VertexAttribPointer(0, 3, OpenGL.FLOAT, OpenGL.FALSE, 9 * size_of(f32), 0)
    OpenGL.EnableVertexAttribArray(1)
    OpenGL.VertexAttribPointer(1, 4, OpenGL.FLOAT, OpenGL.FALSE, 9 * size_of(f32), 3 * size_of(f32))
    OpenGL.EnableVertexAttribArray(2)
    OpenGL.VertexAttribPointer(2, 2, OpenGL.FLOAT, OpenGL.FALSE, 9 * size_of(f32), 7 * size_of(f32))

    return
}

Destroy :: proc(buffer: ^VertexBuffer) {
    OpenGL.DeleteBuffers(1, &buffer.VBO)
}
