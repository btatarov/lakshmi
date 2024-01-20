package main

import "core:os"

import Lua "lua"
import Window "window"

main :: proc() {
    L := Lua.Init()

    Window.LuaBind(L)
    defer Window.LuaUnbind(L)

    Lua.Run(L, os.args[1:])
    defer Lua.Destroy(L)
}
