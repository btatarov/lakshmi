package renderer_index_array

import gl "vendor:OpenGL"

VertexArray :: struct {
    id:     u32,

    bind:   proc(arr: ^VertexArray),
    unbind: proc(_: ^VertexArray),
}

Init :: proc() -> (arr: VertexArray) {
    gl.GenVertexArrays(1, &arr.id)
    gl.BindVertexArray(arr.id)
    gl.EnableVertexAttribArray(0)
    gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 9 * size_of(f32), 0)
    gl.EnableVertexAttribArray(1)
    gl.VertexAttribPointer(1, 4, gl.FLOAT, gl.FALSE, 9 * size_of(f32), 3 * size_of(f32))
    gl.EnableVertexAttribArray(2)
    gl.VertexAttribPointer(2, 2, gl.FLOAT, gl.FALSE, 9 * size_of(f32), 7 * size_of(f32))

    arr.bind   = vertex_array_bind
    arr.unbind = vertex_array_unbind

    return
}

Destroy :: proc(arr: ^VertexArray) {
    gl.DeleteVertexArrays(1, &arr.id)
}

vertex_array_bind :: proc(arr: ^VertexArray) {
    gl.BindVertexArray(arr.id)
}

vertex_array_unbind :: proc(_: ^VertexArray) {
    gl.BindVertexArray(0)
}
