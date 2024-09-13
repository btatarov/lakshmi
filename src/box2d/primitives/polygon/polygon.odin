package box2d_poly

import "core:log"

import b2 "vendor:box2d"
import lua "vendor:lua/5.4"

import Box2DEntity "../../entity"

import LakshmiContext "../../../base/context"
import LuaRuntime "../../../lua"

Init :: proc(primitive: ^Box2DEntity.Primitive, vertices: []b2.Vec2, radius: f32) {
    log.debugf("LakshmiBox2DPolygon: Init\n")

    hull := b2.ComputeHull(vertices)
    polygon := b2.MakePolygon(hull, radius)

    primitive.data = polygon
    primitive.type = .Polygon
}

Destroy :: proc(primitive: ^Box2DEntity.Primitive) {
    log.debugf("LakshmiBox2DPolygon: Destroy\n")
}

LuaBind :: proc(L: ^lua.State) {
    @static reg_table: []lua.L_Reg = {
        { "new", _init },
        { nil, nil },
    }
    LuaRuntime.BindClass(L, "LakshmiBox2DPolygon", &reg_table, __gc)
}

LuaUnbind :: proc(L: ^lua.State) {
    // EMPTY
}

_init :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    primitive := (^Box2DEntity.Primitive)(lua.newuserdata(L, size_of(Box2DEntity.Primitive)))

    verices: [b2.maxPolygonVertices]b2.Vec2
    vertices_count: int

    lua.pushnil(L)
    for idx := 0 ; lua.next(L, 1) != 0; idx += 1 {
        val := lua.tonumber(L, -1)
        lua.pop(L, 1)

        if idx % 2 == 0 {
            verices[vertices_count].x = f32(val)
        } else {
            verices[vertices_count].y = f32(val)
            vertices_count += 1
        }
    }

    radius := lua.tonumber(L, 2)

    Init(primitive, verices[:vertices_count], f32(radius))

    LuaRuntime.BindClassMetatable(L, "LakshmiBox2DPolygon")

    return 1
}

__gc :: proc "c" (L: ^lua.State) -> i32 {
    context = LakshmiContext.GetDefault()

    primitive := (^Box2DEntity.Primitive)(lua.touserdata(L, 1))
    Destroy(primitive)

    return 0
}
