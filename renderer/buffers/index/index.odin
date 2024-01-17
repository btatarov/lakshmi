package index

import "vendor:OpenGL"

IndexBuffer :: struct {
    EBO     : u32,
}

Init :: proc(indecies: rawptr, size: int) -> (buffer : IndexBuffer) {
    OpenGL.GenBuffers(1, &buffer.EBO)
    OpenGL.BindBuffer(OpenGL.ELEMENT_ARRAY_BUFFER, buffer.EBO)
    OpenGL.BufferData(OpenGL.ELEMENT_ARRAY_BUFFER, size, indecies, OpenGL.STATIC_DRAW)

    return
}

Destroy :: proc(buffer: ^IndexBuffer) {
    OpenGL.DeleteBuffers(1, &buffer.EBO)
}
