package window

import "vendor:glfw"
import "vendor:OpenGL"

import "../renderer"

OPENGL_VERSION_MAJOR :: 3
OPENGL_VERSION_MINOR :: 3

// TODO: struct (OOP)
window : glfw.WindowHandle

Init :: proc(title : cstring, width, height : i32) {
    assert(bool(glfw.Init()), "GLFW init failed")

    glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, OPENGL_VERSION_MAJOR)
    glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, OPENGL_VERSION_MINOR)
    glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)

    window = glfw.CreateWindow(width, height, title, nil, nil)
    assert(window != nil, "Failed to create GLFW window")

    glfw.SetKeyCallback(window, OnKeyboardCallback)
    glfw.SetFramebufferSizeCallback(window, OnWindowResizeCallback)

    glfw.MakeContextCurrent(window)
    glfw.SwapInterval(1)

    OpenGL.load_up_to(OPENGL_VERSION_MAJOR, OPENGL_VERSION_MINOR, glfw.gl_set_proc_address)

    width, height := glfw.GetFramebufferSize(window)

    renderer.Init(width, height)
}

Destroy :: proc() {
    renderer.Destroy()

    glfw.DestroyWindow(window)
    glfw.Terminate()
}

OnWindowResizeCallback :: proc "c" (window : glfw.WindowHandle, width, height : i32) {
    renderer.RefreshViewport(width, height)
}

OnKeyboardCallback :: proc "c" (window : glfw.WindowHandle, key, scancode, action, mode : i32) {
    if action == glfw.PRESS && key == glfw.KEY_ESCAPE {
        glfw.SetWindowShouldClose(window, true)
    }
}

MainLoop :: proc() {
    for ! glfw.WindowShouldClose(window) {
        renderer.Render()
        glfw.PollEvents()
        glfw.SwapBuffers(window)
    }
}
