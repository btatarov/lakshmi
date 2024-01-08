package main

import "core:fmt"
import SDL "vendor:sdl2"

main :: proc() {
    assert(SDL.Init(SDL.INIT_VIDEO) == 0, SDL.GetErrorString())
    defer SDL.Quit()

    window := SDL.CreateWindow(
        "Lakshimi",
        SDL.WINDOWPOS_CENTERED,
        SDL.WINDOWPOS_CENTERED,
        1024,
        768,
        SDL.WINDOW_SHOWN,
    )
    assert(window != nil, SDL.GetErrorString())
    defer SDL.DestroyWindow(window)

    renderer := SDL.CreateRenderer(window, -1, SDL.RENDERER_ACCELERATED)
    assert(renderer != nil, SDL.GetErrorString())
    defer SDL.DestroyRenderer(renderer)

    event : SDL.Event
    game_loop : for {
        for SDL.PollEvent(&event) {
            #partial switch event.type {
            case SDL.EventType.QUIT:
                break game_loop

            case SDL.EventType.KEYDOWN:
                #partial switch event.key.keysym.scancode {
                case .ESCAPE:
                    break game_loop
                }
            }
        }

        SDL.RenderPresent(renderer)
        SDL.SetRenderDrawColor(renderer, 0, 0, 0, 100)
        SDL.RenderClear(renderer)
    }
}
