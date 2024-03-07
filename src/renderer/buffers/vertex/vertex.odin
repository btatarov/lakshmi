package vertex

import "vendor:OpenGL"

VertexBuffer :: struct {
    id:     u32,
    pos:    i32,

    add:    proc(buffer: ^VertexBuffer, vertices: []f32, size: int),
    bind:   proc(buffer: ^VertexBuffer),
    unbind: proc(buffer: ^VertexBuffer),
}

Init :: proc(size: int) -> (buffer : VertexBuffer) {
    OpenGL.GenBuffers(1, &buffer.id)
    OpenGL.BindBuffer(OpenGL.ARRAY_BUFFER, buffer.id)
    OpenGL.BufferData(OpenGL.ARRAY_BUFFER, size, nil, OpenGL.DYNAMIC_DRAW)

    buffer.pos  = 0

    buffer.add    = vertex_buffer_add
    buffer.bind   = vertex_buffer_bind
    buffer.unbind = vertex_buffer_unbind

    return
}

Destroy :: proc(buffer: ^VertexBuffer) {
    OpenGL.DeleteBuffers(1, &buffer.id)
}

vertex_buffer_add :: proc(buffer: ^VertexBuffer, vertices: []f32, size: int) {
    OpenGL.BindBuffer(OpenGL.ARRAY_BUFFER, buffer.id)
    OpenGL.BufferSubData(OpenGL.ARRAY_BUFFER, int(buffer.pos), size, &vertices[0])
    buffer.pos += i32(size)
}

vertex_buffer_bind :: proc(buffer: ^VertexBuffer) {
    OpenGL.BindBuffer(OpenGL.ARRAY_BUFFER, buffer.id)
}

vertex_buffer_unbind :: proc(_: ^VertexBuffer) {
    OpenGL.BindBuffer(OpenGL.ARRAY_BUFFER, 0)
}
