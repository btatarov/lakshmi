package window

import "core:fmt"
import "core:log"

import "vendor:glfw"
import lua "vendor:lua/5.4"
import "vendor:OpenGL"

import Keyboard "../input/keyboard"
import LakshmiContext "../base/context"
import LuaRuntime "../lua"
import Renderer "../renderer"

OPENGL_VERSION_MAJOR :: 4
OPENGL_VERSION_MINOR :: 1

Window :: struct {
    handle: glfw.WindowHandle,
    title:  cstring,
    frames: i32,
    time:   f64,
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
        { "open",       _open },
        { "setVsync",   _setVsyc },
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

    time: f64
    delta_time: f64
    frame_time := glfw.GetTime()
    for ! glfw.WindowShouldClose(window.handle) {
        // calculate delta time
        time = glfw.GetTime()
        delta_time = time - frame_time
        frame_time = time

        // update totals
        window.frames += 1
        window.time += delta_time

        // set window title to show FPS
        title := fmt.ctprintf("%s - FPS: %f", window.title, 1 / delta_time)
        glfw.SetWindowTitle(window.handle, title)

        // handle events
        glfw.PollEvents()

        // TODO: logic

        // render
        Renderer.Render()
        glfw.SwapBuffers(window.handle)

        // cleanup
        free_all(context.temp_allocator)
    }
}

SetVsync :: proc(enabled : bool) {
    if enabled {
        glfw.SwapInterval(1)
    } else {
        glfw.SwapInterval(0)
    }
}

OnWindowResizeCallback :: proc "c" (window : glfw.WindowHandle, width, height : i32) {
    context = LakshmiContext.GetDefault()

    Renderer.RefreshViewport(width, height)
}

OnKeyboardCallback :: proc "c" (window : glfw.WindowHandle, key, scancode, action, mode : i32) {
    context = LakshmiContext.GetDefault()

    Keyboard.LuaHandleCallback(key, action)

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

_setVsyc :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    enabled := bool(lua.toboolean(L, 1))
    SetVsync(enabled)

    return 0
}
