package box2d_box

import "core:log"

import b2 "vendor:box2d"
import lua "vendor:lua/5.4"

import LakshmiContext "../../../base/context"
import LuaRuntime "../../../lua"

Init :: proc(polygon: ^b2.Polygon, w, h: f32) {
    log.debugf("LakshmiBox2DBox: Init\n")

    box := b2.MakeBox(w, h)
    polygon.vertices = box.vertices
    polygon.normals = box.normals
    polygon.centroid = box.centroid
    polygon.radius = box.radius
    polygon.count = box.count
}

Destroy :: proc(polygon: ^b2.Polygon) {
    log.debugf("LakshmiBox2DBox: Destroy\n")
}

LuaBind :: proc(L: ^lua.State) {
    @static reg_table: []lua.L_Reg = {
        { "new", _init },
        { nil, nil },
    }
    LuaRuntime.BindClass(L, "LakshmiBox2DBox", &reg_table, __gc)
}

LuaUnbind :: proc(L: ^lua.State) {
    // EMPTY
}

_init :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    polygon := (^b2.Polygon)(lua.newuserdata(L, size_of(b2.Polygon)))
    w := lua.tonumber(L, 1)
    h := lua.tonumber(L, 2)

    Init(polygon, f32(w), f32(h))

    LuaRuntime.BindClassMetatable(L, "LakshmiBox2DBox")

    return 1
}

__gc :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    polygon := (^b2.Polygon)(lua.touserdata(L, 1))
    Destroy(polygon)

    return 0
}
