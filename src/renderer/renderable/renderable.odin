package renderable

Renderable_Type :: enum {
    Sprite,
    Text,
}

Renderable :: struct {
    renderable_type: Renderable_Type,
}
