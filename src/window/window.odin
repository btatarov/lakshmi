package window

import "core:fmt"
import "core:log"

import "vendor:glfw"
import lua "vendor:lua/5.4"
import "vendor:OpenGL"

import LakshmiContext "../base/context"
import LuaRuntime "../lua"
import Renderer "../renderer"

OPENGL_VERSION_MAJOR :: 3
OPENGL_VERSION_MINOR :: 3

Window :: struct {
    handle: glfw.WindowHandle,
    title: cstring,
}

@private window: Window

Init :: proc(title : cstring, width, height : i32) {
    log.debugf("LakshmiWindow: Init\n")

    assert(bool(glfw.Init()), "GLFW init failed")

    glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, OPENGL_VERSION_MAJOR)
    glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, OPENGL_VERSION_MINOR)
    glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)

    window.title = title
    window.handle = glfw.CreateWindow(width, height, title, nil, nil)
    assert(window.handle != nil, "Failed to create GLFW window")

    glfw.SetKeyCallback(window.handle, OnKeyboardCallback)
    glfw.SetFramebufferSizeCallback(window.handle, OnWindowResizeCallback)

    glfw.MakeContextCurrent(window.handle)
    glfw.SwapInterval(1)

    OpenGL.load_up_to(OPENGL_VERSION_MAJOR, OPENGL_VERSION_MINOR, glfw.gl_set_proc_address)

    fb_width, fb_height := glfw.GetFramebufferSize(window.handle)
    Renderer.Init(fb_width, fb_height)
}

Destroy :: proc() {
    log.debugf("LakshmiWindow: Destroy\n")

    Renderer.Destroy()

    glfw.DestroyWindow(window.handle)
    glfw.Terminate()
}

LuaBind :: proc(L: ^lua.State) {
    @static reg_table: []lua.L_Reg = {
        { "open", _open },
        { nil, nil },
    }
    LuaRuntime.BindSingleton(L, "LakshmiWindow", &reg_table)
}

LuaUnbind :: proc(L: ^lua.State) {
    Destroy()
}

MainLoop :: proc() {
    context = LakshmiContext.GetDefault()  // TODO: we need this evey time we use the logger

    log.debugf("LakshmiWindow: MainLoop\n")

    frame_time := 0.0
    delta_time := 0.0
    for ! glfw.WindowShouldClose(window.handle) {
        time := glfw.GetTime()
        delta_time = time - frame_time
        frame_time = time

        // set window title to show FPS
        title := fmt.ctprintf("%s - FPS: %f", window.title, 1 / delta_time)
        glfw.SetWindowTitle(window.handle, title)

        Renderer.Render()

        glfw.PollEvents()
        glfw.SwapBuffers(window.handle)

        free_all(context.temp_allocator)
    }
}

OnWindowResizeCallback :: proc "c" (window : glfw.WindowHandle, width, height : i32) {
    context = LakshmiContext.GetDefault()

    Renderer.RefreshViewport(width, height)
}

OnKeyboardCallback :: proc "c" (window : glfw.WindowHandle, key, scancode, action, mode : i32) {
    if action == glfw.PRESS && key == glfw.KEY_ESCAPE {
        glfw.SetWindowShouldClose(window, true)
    }
}

_open :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    title := lua.L_checkstring(L, 1)
    width := i32(lua.L_checkinteger(L, 2))
    height := i32(lua.L_checkinteger(L, 3))
    Init(title, width, height)

    return 0
}
