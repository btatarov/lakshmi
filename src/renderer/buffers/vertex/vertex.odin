package vertex

import "vendor:OpenGL"

VertexBuffer :: struct {
    id:     u32,
    size:   i32,

    bind:   proc(buffer: ^VertexBuffer, vertices: []f32, size: int),
    unbind: proc(buffer: ^VertexBuffer),
}

Init :: proc() -> (buffer : VertexBuffer) {
    OpenGL.GenBuffers(1, &buffer.id)

    buffer.bind   = vertex_buffer_bind
    buffer.unbind = vertex_buffer_unbind

    return
}

Destroy :: proc(buffer: ^VertexBuffer) {
    OpenGL.DeleteBuffers(1, &buffer.id)
}

vertex_buffer_bind :: proc(buffer: ^VertexBuffer, vertices: []f32, size: int) {
    OpenGL.BindBuffer(OpenGL.ARRAY_BUFFER, buffer.id)
    OpenGL.BufferData(OpenGL.ARRAY_BUFFER, size, &vertices[0], OpenGL.STATIC_DRAW)

    buffer.size = i32(size)
}

vertex_buffer_unbind :: proc(_: ^VertexBuffer) {
    OpenGL.BindBuffer(OpenGL.ARRAY_BUFFER, 0)
}
