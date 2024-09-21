package input

import lua "vendor:lua/5.4"

import Keyboard "keyboard"
import Gamepad "gamepad"

LuaBind :: proc(L: ^lua.State) {
    Keyboard.LuaBind(L)
    Gamepad.LuaBind(L)
}

LuaUnbind :: proc(L: ^lua.State) {
    Keyboard.LuaUnbind(L)
    Gamepad.LuaUnbind(L)
}
