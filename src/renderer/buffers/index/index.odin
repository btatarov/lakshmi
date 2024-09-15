package renderer_index_buffer

import gl "vendor:OpenGL"

IndexBuffer :: struct {
    id:     u32,
    count:  i32,  // TODO: remove (and also from functions params)
    pos:    i32,

    add:    proc(buffer: ^IndexBuffer, indices: []u32, count: i32),
    bind:   proc(buffer: ^IndexBuffer),
    unbind: proc(buffer: ^IndexBuffer),
}

Init :: proc(count: i32) -> (buffer : IndexBuffer) {
    gl.GenBuffers(1, &buffer.id)
    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, buffer.id)
    gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, int(count) * size_of(u32), nil, gl.DYNAMIC_DRAW)

    buffer.count = count
    buffer.pos   = 0

    buffer.add    = index_buffer_add
    buffer.bind   = index_buffer_bind
    buffer.unbind = index_buffer_unbind

    return
}

Destroy :: proc(buffer: ^IndexBuffer) {
    gl.DeleteBuffers(1, &buffer.id)
}

index_buffer_add :: proc(buffer: ^IndexBuffer, indices: []u32, count: i32) {
    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, buffer.id)
    gl.BufferSubData(gl.ELEMENT_ARRAY_BUFFER, int(buffer.pos), int(count) * size_of(u32), &indices[0])

    buffer.count += count
    buffer.pos   += count * size_of(u32)
}

index_buffer_bind :: proc(buffer: ^IndexBuffer) {
    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, buffer.id)
}

index_buffer_unbind :: proc(_: ^IndexBuffer) {
    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, 0)
}
