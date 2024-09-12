LakshmiWindow.open('Lakshmi', 1024, 768)
LakshmiWindow.setVsync(true)
LakshmiRenderer.setClearColor(0.3, 0.3, 0.3, 1.0)

LakshmiKeyboard.setCallback(function(key, action)
    if action == LakshmiKeyboard.KEY_PRESS_ACTION and key == LakshmiKeyboard.KEY_ESCAPE then
        LakshmiKeyboard.clearCallback()
        LakshmiWindow.quit()
    end
end)

layer = LakshmiLayer.new()
LakshmiRenderer.add(layer)

LakshmiBox2DWorld.init()
LakshmiBox2DWorld.setUnitsPerMeter(100)
LakshmiBox2DWorld.setGravity(0, -9.80665)
LakshmiBox2DWorld.setUpdateSteps(8)

floor = LakshmiBox2DBox.new(700, 35)
floor:setBodyType(LakshmiBox2DWorld.BODY_TYPE_STATIC)
floor:setPos(0, - 768 / 2 + 35)

x, y = floor:getPos()
floor_sprite = LakshmiSprite.new('test/box2d/floor.png')
floor_sprite:setPos(x, y)
layer:add(floor_sprite)

boxes = {}
for i = 1, 15 do
    for j = 1, 12 do
        local box = LakshmiBox2DBox.new(15, 15)
        box:setBodyType(LakshmiBox2DWorld.BODY_TYPE_DYNAMIC)
        box:setPos(- 1024 / 2 + 50 + 65 * (i - 1), 768 / 2 - (50 + 55 * (j - 1)))
        box:setRot(math.random() * 360)
        box:setFriction(0.6)
        box:setRestitution(0.5)

        local sprite = LakshmiSprite.new('test/box2d/crate.png')
        sprite:setPos(box:getPos())
        sprite:setRot(box:getRot())
        layer:add(sprite)

        table.insert(boxes, {box = box, sprite = sprite})
    end
end

LakshmiWindow.setLoopCallback(function(delta)
    LakshmiBox2DWorld.update(delta)

    for _, box in ipairs(boxes) do
        box.sprite:setPos(box.box:getPos())
        box.sprite:setRot(box.box:getRot())
    end
end)
