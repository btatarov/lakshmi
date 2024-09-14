package audio

import lua "vendor:lua/5.4"

import System "system"
import Channel "channel"

LuaBind :: proc(L: ^lua.State) {
    System.LuaBind(L)
    Channel.LuaBind(L)
}

LuaUnbind :: proc(L: ^lua.State) {
    System.LuaUnbind(L)
    Channel.LuaUnbind(L)
}
