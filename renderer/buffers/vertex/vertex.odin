package vertex

import "vendor:OpenGL"

VertexBuffer :: struct {
    VBO     : u32,
}

Init :: proc(vertices: rawptr, size: int) -> (buffer : VertexBuffer) {
    OpenGL.GenBuffers(1, &buffer.VBO)
    OpenGL.BindBuffer(OpenGL.ARRAY_BUFFER, buffer.VBO)
    OpenGL.BufferData(OpenGL.ARRAY_BUFFER, size, vertices, OpenGL.STATIC_DRAW)

    return
}

Destroy :: proc(buffer: ^VertexBuffer) {
    OpenGL.DeleteBuffers(1, &buffer.VBO)
}
