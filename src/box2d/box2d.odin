package box2d

import lua "vendor:lua/5.4"

import World "world"
import Entity "entity"
import Box "shapes/box"

LuaBind :: proc(L: ^lua.State) {
    World.LuaBind(L)
    Entity.LuaBind(L)
    Box.LuaBind(L)
}

LuaUnbind :: proc(L: ^lua.State) {
    World.LuaUnbind(L)
    Entity.LuaUnbind(L)
    Box.LuaUnbind(L)
}
