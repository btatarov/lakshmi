package index

import "vendor:OpenGL"

IndexBuffer :: struct {
    id      : u32,
    count   : i32,
}

Init :: proc(indecies: []u32, count: i32) -> (buffer : IndexBuffer) {
    OpenGL.GenBuffers(1, &buffer.id)
    OpenGL.BindBuffer(OpenGL.ELEMENT_ARRAY_BUFFER, buffer.id)
    OpenGL.BufferData(OpenGL.ELEMENT_ARRAY_BUFFER, size_of(indecies) * int(count), &indecies[0], OpenGL.STATIC_DRAW)

    buffer.count = count

    return
}

Destroy :: proc(buffer: ^IndexBuffer) {
    OpenGL.DeleteBuffers(1, &buffer.id)
}
