package main

import "core:os"

import Lua "lua"
import Window "window"

main :: proc() {
    Lua.Init()
    Lua.Run(os.args[1:])
    defer Lua.Destroy()

    Window.Init("Lakshimi", 1024, 768)
    Window.MainLoop()
    defer Window.Destroy()
}
