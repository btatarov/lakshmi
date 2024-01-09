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
    glfw.SetWindowRefreshCallback(window, HostRefreshCallback)

    glfw.MakeContextCurrent(window)
    glfw.SwapInterval(1)

    OpenGL.load_up_to(3,3, glfw.gl_set_proc_address)
    OpenGL.Viewport(0, 0, width, height)

    return window
}

HostRefreshCallback :: proc "c" (window : glfw.WindowHandle) {
    width, height := glfw.GetFramebufferSize(window)
    OpenGL.Viewport(0, 0, width, height)
}

HostKeyCallback :: proc "c" (window : glfw.WindowHandle, key, scancode, action, mode : i32) {
    if action == glfw.PRESS && key == glfw.KEY_ESCAPE {
        glfw.SetWindowShouldClose(window, true)
    }
}

HostMainLoop :: proc(window : glfw.WindowHandle) {
    for ! glfw.WindowShouldClose(window) {
        glfw.PollEvents()

        OpenGL.ClearColor(0.2, 0.3, 0.3, 1.0)
        OpenGL.Clear(OpenGL.COLOR_BUFFER_BIT | OpenGL.DEPTH_BUFFER_BIT)

        glfw.SwapBuffers(window)
    }
}

main :: proc() {
    assert(glfw.Init() == true, "GLFW init failed")
    defer glfw.Terminate()

    window := HostCreateWindow("Lakshimi", 1024, 768)
    defer glfw.DestroyWindow(window)

    HostMainLoop(window)
}
