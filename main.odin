package main

import Window "engine/window"

main :: proc() {
    Window.Init("Lakshimi", 1024, 768)
    defer Window.Destroy()

    Window.MainLoop()
}
