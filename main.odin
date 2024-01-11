package main

import "vendor:glfw"
import "vendor:OpenGL"

import "engine/renderer"

CreateWindow :: proc(title : cstring, width, height : i32) -> glfw.WindowHandle {
    glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, 3)
    glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, 3)
    glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)

    window := glfw.CreateWindow(width, height, title, nil, nil)
    assert(window != nil, "Failed to create GLFW window")

    glfw.SetKeyCallback(window, OnKeyboardCallback)
    glfw.SetFramebufferSizeCallback(window, OnWindowResizeCallback)

    glfw.MakeContextCurrent(window)
    glfw.SwapInterval(1)

    OpenGL.load_up_to(3, 3, glfw.gl_set_proc_address)

    width, height := glfw.GetFramebufferSize(window)
    renderer.Init(width, height)

    return window
}

OnWindowResizeCallback :: proc "c" (window : glfw.WindowHandle, width, height : i32) {
    renderer.RefreshViewport(width, height)
}

OnKeyboardCallback :: proc "c" (window : glfw.WindowHandle, key, scancode, action, mode : i32) {
    if action == glfw.PRESS && key == glfw.KEY_ESCAPE {
        glfw.SetWindowShouldClose(window, true)
    }
}

MainLoop :: proc(window : glfw.WindowHandle) {
    for ! glfw.WindowShouldClose(window) {
        renderer.Render()
        glfw.PollEvents()
        glfw.SwapBuffers(window)
    }
}

main :: proc() {
    assert(bool(glfw.Init()), "GLFW init failed")
    defer glfw.Terminate()

    window := CreateWindow("Lakshimi", 1024, 768)
    defer glfw.DestroyWindow(window)

    MainLoop(window)
    defer renderer.Destroy()
}
