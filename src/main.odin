package main

import "core:fmt"
import "core:mem"
import "core:os"

import JSON "json"
import LuaRuntime "lua"

import LakshmiContext "base/context"
import Renderer "renderer"
import Sprite "renderer/sprite"
import Window "window"

main :: proc() {
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
    }

    LakshmiContext.Init()
    defer LakshmiContext.Destroy()

    L := LuaRuntime.Init()

    Window.LuaBind(L)
    defer Window.LuaUnbind(L)

    Renderer.LuaBind(L)
    defer Renderer.LuaUnbind(L)

    Sprite.LuaBind(L)
    defer Sprite.LuaUnbind(L)

    JSON.LuaBind(L)
    defer JSON.LuaUnbind(L)

    LuaRuntime.Run(L, os.args[1:])
    defer LuaRuntime.Destroy(L)

    Window.MainLoop()
}
