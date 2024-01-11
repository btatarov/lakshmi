package main

import "vendor:OpenGL"
import "vendor:glfw"

HostCreateWindow :: proc(title : cstring, width, height : i32) -> glfw.WindowHandle {
    glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, 3)
    glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, 3)
    glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)

    window := glfw.CreateWindow(width, height, title, nil, nil)
    assert(window != nil, "Failed to create GLFW window")

    glfw.SetKeyCallback(window, HostKeyCallback)
    glfw.SetFramebufferSizeCallback(window, HostWindowResizeCallback)

    glfw.MakeContextCurrent(window)
    glfw.SwapInterval(1)

    OpenGL.load_up_to(3, 3, glfw.gl_set_proc_address)
    OpenGL.Viewport(0, 0, width, height)

    return window
}

HostWindowResizeCallback :: proc "c" (window : glfw.WindowHandle, width, height : i32) {
    OpenGL.Viewport(0, 0, width, height)
}

HostKeyCallback :: proc "c" (window : glfw.WindowHandle, key, scancode, action, mode : i32) {
    if action == glfw.PRESS && key == glfw.KEY_ESCAPE {
        glfw.SetWindowShouldClose(window, true)
    }
}

HostMainLoop :: proc(window : glfw.WindowHandle) {
    VBO : u32
    OpenGL.GenBuffers(1, &VBO)
    OpenGL.BindBuffer(OpenGL.ARRAY_BUFFER, VBO)
    defer OpenGL.DeleteBuffers(1, &VBO)

    VAO : u32
    OpenGL.GenVertexArrays(1, &VAO)
    OpenGL.BindVertexArray(VAO)
    OpenGL.BindBuffer(OpenGL.ARRAY_BUFFER, VBO)
    defer OpenGL.DeleteVertexArrays(1, &VAO)

    // triangle
    vertices : [3 * 3] f32 = {
        -0.5, -0.5, 0.0,
         0.5, -0.5, 0.0,
         0.0,  0.5, 0.0,
    }

    OpenGL.BufferData(OpenGL.ARRAY_BUFFER, size_of(vertices), &vertices, OpenGL.STATIC_DRAW)
    OpenGL.VertexAttribPointer(0, 3, OpenGL.FLOAT, false, 3 * size_of(f32), 0)
    OpenGL.EnableVertexAttribArray(0)

    // shaders
    vertex_shader := string(#load("temp/vertex.glsl"))
    fragment_shader := string(#load("temp/fragment.glsl"))
    global_shader, ok := OpenGL.load_shaders_source(vertex_shader, fragment_shader)
    assert(ok, "Failed to load and compile shaders.")
    defer OpenGL.DeleteProgram(global_shader)


    for ! glfw.WindowShouldClose(window) {
        glfw.PollEvents()

        OpenGL.ClearColor(0.2, 0.3, 0.3, 1.0)
        OpenGL.Clear(OpenGL.COLOR_BUFFER_BIT | OpenGL.DEPTH_BUFFER_BIT)

        OpenGL.UseProgram(global_shader)
        OpenGL.BindVertexArray(VAO)
        OpenGL.DrawArrays(OpenGL.TRIANGLES, 0, 3)

        glfw.SwapBuffers(window)
    }
}

main :: proc() {
    assert(bool(glfw.Init()), "GLFW init failed")
    defer glfw.Terminate()

    window := HostCreateWindow("Lakshimi", 1024, 768)
    defer glfw.DestroyWindow(window)

    HostMainLoop(window)
}
