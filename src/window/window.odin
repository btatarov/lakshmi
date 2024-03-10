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

    glfw.SetErrorCallback(OnErrorCallback)

    assert(bool(glfw.Init()), "GLFW init failed")

    glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, OPENGL_VERSION_MAJOR)
    glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, OPENGL_VERSION_MINOR)
    glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)

    when ODIN_OS == .Darwin {
        glfw.WindowHint(glfw.OPENGL_FORWARD_COMPAT, glfw.TRUE)
        glfw.WindowHint(glfw.COCOA_RETINA_FRAMEBUFFER, glfw.FALSE)
    }

    window.title = title
    window.handle = glfw.CreateWindow(width, height, title, nil, nil)
    assert(window.handle != nil, "Failed to create GLFW window")

    glfw.SetKeyCallback(window.handle, OnKeyboardCallback)
    glfw.SetFramebufferSizeCallback(window.handle, OnWindowResizeCallback)

    glfw.MakeContextCurrent(window.handle)

    OpenGL.load_up_to(OPENGL_VERSION_MAJOR, OPENGL_VERSION_MINOR, glfw.gl_set_proc_address)

    fb_width, fb_height := glfw.GetFramebufferSize(window.handle)
    fb_scale_x, fb_scale_y := glfw.GetWindowContentScale(window.handle)
    Renderer.Init(fb_width, fb_height)
    Renderer.RefreshViewport(fb_width / i32(fb_scale_x), fb_height / i32(fb_scale_y))
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
        { "quit",       _quit },
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

OnErrorCallback :: proc "c" (error : i32, description : cstring) {
    context = LakshmiContext.GetDefault()

    log.errorf("GLFW error: %s\n", description)
}

OnKeyboardCallback :: proc "c" (window : glfw.WindowHandle, key, scancode, action, mode : i32) {
    context = LakshmiContext.GetDefault()

    Keyboard.LuaHandleCallback(key, action)
}

OnWindowResizeCallback :: proc "c" (window : glfw.WindowHandle, width, height : i32) {
    context = LakshmiContext.GetDefault()

    Renderer.RefreshViewport(width, height)
}

SetVsync :: proc(enabled : bool) {
    if enabled {
        glfw.SwapInterval(1)
    } else {
        glfw.SwapInterval(0)
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

_quit :: proc "c" (L: ^lua.State) -> i32 {
    glfw.SetWindowShouldClose(window.handle, true)

    return 0
}
