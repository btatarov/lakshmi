package main

import Window "window"

main :: proc() {
    Window.Init("Lakshimi", 1024, 768)
    defer Window.Destroy()

    Window.MainLoop()
}
