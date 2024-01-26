package vertex

import "vendor:OpenGL"

VertexBuffer :: struct {
    id:     u32,
    size:   i32,
}

Init :: proc(vertices: []f32, size: int) -> (buffer : VertexBuffer) {
    OpenGL.GenBuffers(1, &buffer.id)
    OpenGL.BindBuffer(OpenGL.ARRAY_BUFFER, buffer.id)
    OpenGL.BufferData(OpenGL.ARRAY_BUFFER, size, &vertices[0], OpenGL.STATIC_DRAW)

    buffer.size = i32(size)

    return
}

Destroy :: proc(buffer: ^VertexBuffer) {
    OpenGL.DeleteBuffers(1, &buffer.id)
}
