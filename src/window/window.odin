package window

import "core:log"

import "vendor:glfw"
import lua "vendor:lua/5.4"
import "vendor:OpenGL"

import LakshmiContext "../base/context"
import LuaRuntime "../lua"
import Renderer "../renderer"
import Sprite "../renderer/sprite"

OPENGL_VERSION_MAJOR :: 3
OPENGL_VERSION_MINOR :: 3

window : glfw.WindowHandle

Init :: proc(title : cstring, width, height : i32) {
    log.debugf("LakshmiWindow: Init\n")

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
    Renderer.Init(width, height)
}

Destroy :: proc() {
    log.debugf("LakshmiWindow: Destroy\n")

    Renderer.Destroy()

    glfw.DestroyWindow(window)
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
    log.debugf("LakshmiWindow: MainLoop\n", "test")

    for ! glfw.WindowShouldClose(window) {
        Renderer.Render()

        glfw.PollEvents()
        glfw.SwapBuffers(window)

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
