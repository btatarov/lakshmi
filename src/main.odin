package main

import "core:fmt"
import "core:mem"
import "core:os"

import JSON "json"
import LuaRuntime "lua"

import Audio "audio"
import Input "input"
import LakshmiContext "base/context"
import Renderer "renderer"
import Camera "renderer/camera"
import Layer "renderer/layer"
import Sprite "renderer/sprite"
import Text "renderer/text"
import Window "window"

import Box2D "box2d"

main :: proc() {
    LakshmiContext.Init()
    defer LakshmiContext.Destroy()

    context = LakshmiContext.GetDefault()

    when ODIN_DEBUG {
        tracking_allocator: mem.Tracking_Allocator
        mem.tracking_allocator_init(&tracking_allocator, context.allocator)
        context.allocator = mem.tracking_allocator(&tracking_allocator)
        defer if len(tracking_allocator.allocation_map) > 0 || len(tracking_allocator.bad_free_array) > 0 {
            fmt.println()
            for _, leak in tracking_allocator.allocation_map {
                fmt.printf("%v leaked %v bytes\n", leak.location, leak.size)
            }
            for bad_free in tracking_allocator.bad_free_array {
                fmt.printf("%v allocation %p was freed badly\n", bad_free.location, bad_free.memory)
            }
        }
    } else {
        // HACK: avoid compile warnings
        m: mem.Allocator_Error; _ = m
        n: fmt.Info; _ = n
    }

    LuaRuntime.Init()

    L := LuaRuntime.GetState()

    Audio.LuaBind(L)
    defer Audio.LuaUnbind(L)

    Input.LuaBind(L)
    defer Input.LuaUnbind(L)

    Window.LuaBind(L)
    defer Window.LuaUnbind(L)

    Renderer.LuaBind(L)
    defer Renderer.LuaUnbind(L)

    Camera.LuaBind(L)
    defer Camera.LuaUnbind(L)

    Layer.LuaBind(L)
    defer Layer.LuaUnbind(L)

    Sprite.LuaBind(L)
    defer Sprite.LuaUnbind(L)

    Text.LuaBind(L)
    defer Text.LuaUnbind(L)

    Box2D.LuaBind(L)
    defer Box2D.LuaUnbind(L)

    JSON.LuaBind(L)
    defer JSON.LuaUnbind(L)

    LuaRuntime.Run(L, os.args[1:])
    defer LuaRuntime.Destroy(L)

    Window.MainLoop()  // TODO: call on window open
}
