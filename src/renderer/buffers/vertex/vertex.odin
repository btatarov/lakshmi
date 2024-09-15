package renderer_vertex_buffer

import gl "vendor:OpenGL"

VertexBuffer :: struct {
    id:     u32,
    pos:    i32,

    add:    proc(buffer: ^VertexBuffer, vertices: []f32, size: int),
    bind:   proc(buffer: ^VertexBuffer),
    unbind: proc(buffer: ^VertexBuffer),
}

Init :: proc(size: int) -> (buffer : VertexBuffer) {
    gl.GenBuffers(1, &buffer.id)
    gl.BindBuffer(gl.ARRAY_BUFFER, buffer.id)
    gl.BufferData(gl.ARRAY_BUFFER, size, nil, gl.DYNAMIC_DRAW)

    buffer.pos  = 0

    buffer.add    = vertex_buffer_add
    buffer.bind   = vertex_buffer_bind
    buffer.unbind = vertex_buffer_unbind

    return
}

Destroy :: proc(buffer: ^VertexBuffer) {
    gl.DeleteBuffers(1, &buffer.id)
}

vertex_buffer_add :: proc(buffer: ^VertexBuffer, vertices: []f32, size: int) {
    gl.BindBuffer(gl.ARRAY_BUFFER, buffer.id)
    gl.BufferSubData(gl.ARRAY_BUFFER, int(buffer.pos), size, &vertices[0])
    buffer.pos += i32(size)
}

vertex_buffer_bind :: proc(buffer: ^VertexBuffer) {
    gl.BindBuffer(gl.ARRAY_BUFFER, buffer.id)
}

vertex_buffer_unbind :: proc(_: ^VertexBuffer) {
    gl.BindBuffer(gl.ARRAY_BUFFER, 0)
}
