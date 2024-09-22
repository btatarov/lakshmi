package box2d

import lua "vendor:lua/5.4"

import World "world"
import Entity "entity"
import Box "primitives/box"
import Capsule "primitives/capsule"
import Circle "primitives/circle"
import Polygon "primitives/polygon"

LuaBind :: proc(L: ^lua.State) {
    World.LuaBind(L)
    Entity.LuaBind(L)
    Box.LuaBind(L)
    Capsule.LuaBind(L)
    Circle.LuaBind(L)
    Polygon.LuaBind(L)
}

LuaUnbind :: proc(L: ^lua.State) {
    World.LuaUnbind(L)
    Entity.LuaUnbind(L)
    Box.LuaUnbind(L)
    Capsule.LuaUnbind(L)
    Circle.LuaUnbind(L)
    Polygon.LuaUnbind(L)
}

Update :: proc(delta_time: f64) {
    World.Update(delta_time)
}
