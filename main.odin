package main

import "core:os"

import LuaRuntime "lua"
import Window "window"

main :: proc() {
    L := LuaRuntime.Init()

    Window.LuaBind(L)
    defer Window.LuaUnbind(L)

    LuaRuntime.Run(L, os.args[1:])
    defer LuaRuntime.Destroy(L)
}
