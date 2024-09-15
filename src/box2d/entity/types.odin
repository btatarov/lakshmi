package box2d_entity

import b2 "vendor:box2d"

EntityType :: enum {
    Polygon,
    Circle,
    Capsule,
}

CollisionEventType :: enum {
    Begin,
    End,
    Hit,
}

CollisionEvent :: struct {
    self:  ^Entity,
    other: ^Entity,
    type:  CollisionEventType,
}

Primitive :: struct {
    data: union {
        b2.Polygon,
        b2.Circle,
        b2.Capsule,
    },
    type: EntityType,
}

Entity :: struct {
    unique_id: string,
    primitive: ^Primitive,
    body:      b2.BodyDef,
    body_id:   b2.BodyId,
    shape:     b2.ShapeDef,
    shape_id:  b2.ShapeId,

    collision_callbalck_ref: i32,

    handle_collision: proc(entity: ^Entity, event: CollisionEvent),
}
