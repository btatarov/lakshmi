package window

import "core:fmt"
import "core:log"
import "core:strings"
import "core:time"

import "vendor:glfw"
import lua "vendor:lua/5.4"
import gl "vendor:OpenGL"

import Keyboard "../input/keyboard"
import Gamepad "../input/gamepad"
import LakshmiContext "../base/context"
import LuaRuntime "../lua"
import Renderer "../renderer"
import Box2D "../box2d"

OPENGL_VERSION_MAJOR :: 4
OPENGL_VERSION_MINOR :: 1

PHYSICS_TIMESTEP :: 1 / f64(60)
MAX_FRAME_TIME   :: 1 / f64(5)

Window :: struct {
    handle:         glfw.WindowHandle,
    frames:         i64,
    time:           f64,
    title:          string,
}

@private window: Window
@private delta_time: f64
@private frame_duration: f64 = 1 / f64(60)
@private loop_callback_ref: i32 = lua.REFNIL
@private resize_callback_ref: i32 = lua.REFNIL

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

    window.title = strings.clone_from_cstring(title)
    window.handle = glfw.CreateWindow(width, height, title, nil, nil)
    assert(window.handle != nil, "Failed to create GLFW window")

    glfw.SetKeyCallback(window.handle, OnKeyboardCallback)
    glfw.SetFramebufferSizeCallback(window.handle, OnWindowResizeCallback)

    glfw.MakeContextCurrent(window.handle)

    gl.load_up_to(OPENGL_VERSION_MAJOR, OPENGL_VERSION_MINOR, glfw.gl_set_proc_address)

    fb_width, fb_height := glfw.GetFramebufferSize(window.handle)
    fb_scale_x, fb_scale_y := glfw.GetWindowContentScale(window.handle)
    Renderer.Init(fb_width, fb_height)
    Renderer.RefreshViewport(fb_width / i32(fb_scale_x), fb_height / i32(fb_scale_y))
}

Destroy :: proc() {
    if window.handle == nil {
        return
    }

    log.debugf("LakshmiWindow: Destroy\n")

    Renderer.Destroy()

    glfw.DestroyWindow(window.handle)
    glfw.Terminate()
}

LuaBind :: proc(L: ^lua.State) {
    @static reg_table: []lua.L_Reg = {
        { "open",                _open },
        { "clearLoopCallback",   _clearLoopCallback },
        { "clearResizeCallback", _clearResizeCallback },
        { "getDeltaTime",        _getDeltaTime },
        { "getDrawCount",        _getDrawCount },
        { "setLoopCallback",     _setLoopCallback },
        { "setResizeCallback",   _setResizeCallback },
        { "setTargetFPS",        _setTargetFPS },
        { "setVsync",            _setVsyc },
        { "quit",                _quit },
        { nil, nil },
    }
    LuaRuntime.BindSingleton(L, "LakshmiWindow", &reg_table)
}

LuaUnbind :: proc(L: ^lua.State) {
    Destroy()
}

MainLoop :: proc() {
    if window.handle == nil {
        return
    }

    log.debugf("LakshmiWindow: MainLoop\n")


    cur_time: f64
    accumulator: f64
    frame_time := glfw.GetTime()
    for ! glfw.WindowShouldClose(window.handle) {
        // calculate delta time
        cur_time = glfw.GetTime()
        delta_time = clamp(cur_time - frame_time, 0, MAX_FRAME_TIME)
        frame_time = cur_time

        // update totals
        // window.frames += 1
        // window.time += delta_time
        accumulator += delta_time

        // set window title to show FPS
        title := fmt.ctprintf("%s - FPS: %.4f", window.title, 1 / delta_time)
        glfw.SetWindowTitle(window.handle, title)

        // handle events
        glfw.PollEvents()

        // update gamepad
        if glfw.JoystickPresent(glfw.JOYSTICK_1) && glfw.JoystickIsGamepad(glfw.JOYSTICK_1) {
            Gamepad.Update()
        }

        // physics
        for accumulator >= PHYSICS_TIMESTEP {
            Box2D.Update(PHYSICS_TIMESTEP)
            accumulator -= PHYSICS_TIMESTEP
        }

        // logic
        if loop_callback_ref != lua.REFNIL {
            L := LuaRuntime.GetState()

            lua.rawgeti(L, lua.REGISTRYINDEX, lua.Integer(loop_callback_ref))
            lua.pushnumber(L, lua.Number(delta_time))

            status := lua.pcall(L, 1, 0, 0)
            LuaRuntime.CheckOK(L, lua.Status(status))
        }

        // render
        Renderer.Render()
        glfw.SwapBuffers(window.handle)

        // frame limit
        frame_time_spent := glfw.GetTime() - cur_time
        defer if frame_time_spent < frame_duration {
            sleep_time := frame_duration - frame_time_spent
            time.accurate_sleep(time.Duration(sleep_time * f64(time.Second)))
        }

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

    if resize_callback_ref != lua.REFNIL {
        L := LuaRuntime.GetState()

        lua.rawgeti(L, lua.REGISTRYINDEX, lua.Integer(resize_callback_ref))
        lua.pushinteger(L, lua.Integer(width))
        lua.pushinteger(L, lua.Integer(height))

        status := lua.pcall(L, 2, 0, 0)
        LuaRuntime.CheckOK(L, lua.Status(status))
    }
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

_clearLoopCallback :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    if loop_callback_ref != lua.REFNIL {
        lua.L_unref(L, lua.REGISTRYINDEX, loop_callback_ref)
        loop_callback_ref = lua.REFNIL
    }

    return 0
}

_clearResizeCallback :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    if resize_callback_ref != lua.REFNIL {
        lua.L_unref(L, lua.REGISTRYINDEX, resize_callback_ref)
        resize_callback_ref = lua.REFNIL
    }

    return 0
}

_getDeltaTime :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    lua.pushnumber(L, lua.Number(delta_time))

    return 1
}

_getDrawCount :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    count := Renderer.GetDrawCount()
    lua.pushinteger(L, lua.Integer(count))

    return 1
}

_setLoopCallback :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    if ! lua.isfunction(L, 1) {
        log.errorf("LakshmiWindow.setLoopFunc: argument 1 is not a function\n")
        lua.pop(L, 1)
        return 0
    }

    loop_callback_ref = lua.L_ref(L, lua.REGISTRYINDEX)

    return 0
}

_setResizeCallback :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    if ! lua.isfunction(L, 1) {
        log.errorf("LakshmiWindow.setResizeFunc: argument 1 is not a function\n")
        lua.pop(L, 1)
        return 0
    }

    resize_callback_ref = lua.L_ref(L, lua.REGISTRYINDEX)

    return 0
}

_setTargetFPS :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    fps := lua.L_checknumber(L, 1)
    frame_duration = 1 / f64(fps)

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
