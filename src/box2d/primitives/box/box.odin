package box2d_box

import "core:log"

import b2 "vendor:box2d"
import lua "vendor:lua/5.4"

import Box2DEntity "../../entity"

import LakshmiContext "../../../base/context"
import LuaRuntime "../../../lua"

Init :: proc(primitive: ^Box2DEntity.Primitive, width, height, radius: f32) {
    log.debugf("LakshmiBox2DBox: Init\n")

    box: b2.Polygon
    if radius != 0 {
        box = b2.MakeRoundedBox(width, height, radius)
    }
    else {
        box = b2.MakeBox(width, height)
    }

    primitive.data = box
    primitive.type = .Polygon
}

Destroy :: proc(primitive: ^Box2DEntity.Primitive) {
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

    primitive := (^Box2DEntity.Primitive)(lua.newuserdata(L, size_of(Box2DEntity.Primitive)))
    width  := lua.tonumber(L, 1)
    height := lua.tonumber(L, 2)
    radius := lua.tonumber(L, 3)

    Init(primitive, f32(width), f32(height), f32(radius))

    LuaRuntime.BindClassMetatable(L, "LakshmiBox2DBox")

    return 1
}

__gc :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    primitive := (^Box2DEntity.Primitive)(lua.touserdata(L, 1))
    Destroy(primitive)

    return 0
}
