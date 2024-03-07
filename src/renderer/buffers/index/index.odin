package index

import "vendor:OpenGL"

IndexBuffer :: struct {
    id:     u32,
    count:  i32,  // TODO: remove (and also from functions params)
    pos:    i32,

    add:    proc(buffer: ^IndexBuffer, indecies: []u32, count: i32),
    bind:   proc(buffer: ^IndexBuffer),
    unbind: proc(buffer: ^IndexBuffer),
}

Init :: proc(count: i32) -> (buffer : IndexBuffer) {
    OpenGL.GenBuffers(1, &buffer.id)
    OpenGL.BindBuffer(OpenGL.ELEMENT_ARRAY_BUFFER, buffer.id)
    OpenGL.BufferData(OpenGL.ELEMENT_ARRAY_BUFFER, int(count) * size_of(u32), nil, OpenGL.DYNAMIC_DRAW)

    buffer.count = count
    buffer.pos   = 0

    buffer.add    = index_buffer_add
    buffer.bind   = index_buffer_bind
    buffer.unbind = index_buffer_unbind

    return
}

Destroy :: proc(buffer: ^IndexBuffer) {
    OpenGL.DeleteBuffers(1, &buffer.id)
}

index_buffer_add :: proc(buffer: ^IndexBuffer, indecies: []u32, count: i32) {
    OpenGL.BindBuffer(OpenGL.ELEMENT_ARRAY_BUFFER, buffer.id)
    OpenGL.BufferSubData(OpenGL.ELEMENT_ARRAY_BUFFER, int(buffer.pos), int(count) * size_of(u32), &indecies[0])
    buffer.pos += count * size_of(u32)
}

index_buffer_bind :: proc(buffer: ^IndexBuffer) {
    OpenGL.BindBuffer(OpenGL.ELEMENT_ARRAY_BUFFER, buffer.id)
}

index_buffer_unbind :: proc(_: ^IndexBuffer) {
    OpenGL.BindBuffer(OpenGL.ELEMENT_ARRAY_BUFFER, 0)
}
