package index

import "vendor:OpenGL"

IndexBuffer :: struct {
    id      : u32,
    count   : i32,

    bind    : proc(buffer: ^IndexBuffer, indecies: []u32, count: i32),
    unbind  : proc(buffer: ^IndexBuffer),
}

Init :: proc() -> (buffer : IndexBuffer) {
    OpenGL.GenBuffers(1, &buffer.id)

    buffer.bind   = index_buffer_bind
    buffer.unbind = index_buffer_unbind

    return
}

Destroy :: proc(buffer: ^IndexBuffer) {
    OpenGL.DeleteBuffers(1, &buffer.id)
}

index_buffer_bind :: proc(buffer: ^IndexBuffer, indecies: []u32, count: i32) {
    OpenGL.BindBuffer(OpenGL.ELEMENT_ARRAY_BUFFER, buffer.id)
    OpenGL.BufferData(OpenGL.ELEMENT_ARRAY_BUFFER, size_of(indecies) * int(count), &indecies[0], OpenGL.STATIC_DRAW)

    buffer.count = count
}

index_buffer_unbind :: proc(_: ^IndexBuffer) {
    OpenGL.BindBuffer(OpenGL.ELEMENT_ARRAY_BUFFER, 0)
}
