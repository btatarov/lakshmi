package box2d

import lua "vendor:lua/5.4"

import World "world"
import Entity "entity"
import Box "primitives/box"
import Circle "primitives/circle"
import Capsule "primitives/capsule"

LuaBind :: proc(L: ^lua.State) {
    World.LuaBind(L)
    Entity.LuaBind(L)
    Box.LuaBind(L)
    Circle.LuaBind(L)
    Capsule.LuaBind(L)
}

LuaUnbind :: proc(L: ^lua.State) {
    World.LuaUnbind(L)
    Entity.LuaUnbind(L)
    Box.LuaUnbind(L)
    Circle.LuaUnbind(L)
    Capsule.LuaUnbind(L)
}
