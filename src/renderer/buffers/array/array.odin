package array

import "vendor:OpenGL"

VertexArray :: struct {
    id:     u32,
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

    return
}

Destroy :: proc(arr: ^VertexArray) {
    OpenGL.DeleteVertexArrays(1, &arr.id)
}
