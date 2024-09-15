package renderer_index_array

import "vendor:OpenGL"

VertexArray :: struct {
    id:     u32,

    bind:   proc(arr: ^VertexArray),
    unbind: proc(_: ^VertexArray),
}

Init :: proc() -> (arr: VertexArray) {
    OpenGL.GenVertexArrays(1, &arr.id)
    OpenGL.BindVertexArray(arr.id)
    OpenGL.EnableVertexAttribArray(0)
    OpenGL.VertexAttribPointer(0, 3, OpenGL.FLOAT, OpenGL.FALSE, 9 * size_of(f32), 0)
    OpenGL.EnableVertexAttribArray(1)
    OpenGL.VertexAttribPointer(1, 4, OpenGL.FLOAT, OpenGL.FALSE, 9 * size_of(f32), 3 * size_of(f32))
    OpenGL.EnableVertexAttribArray(2)
    OpenGL.VertexAttribPointer(2, 2, OpenGL.FLOAT, OpenGL.FALSE, 9 * size_of(f32), 7 * size_of(f32))

    arr.bind   = vertex_array_bind
    arr.unbind = vertex_array_unbind

    return
}

Destroy :: proc(arr: ^VertexArray) {
    OpenGL.DeleteVertexArrays(1, &arr.id)
}

vertex_array_bind :: proc(arr: ^VertexArray) {
    OpenGL.BindVertexArray(arr.id)
}

vertex_array_unbind :: proc(_: ^VertexArray) {
    OpenGL.BindVertexArray(0)
}
