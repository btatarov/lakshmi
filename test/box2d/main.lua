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
LakshmiBox2DWorld.setGravity(0, 9.80665)
LakshmiBox2DWorld.setUpdateSteps(8)

floor = LakshmiBox2DBox.new(700, 35)
floor:setBodyType(LakshmiBox2DWorld.BODY_TYPE_STATIC)
floor:setPos(0 + 700 - 200, 768 - 35)

x, y = floor:getPos()
floor_sprite = LakshmiSprite.new('test/box2d/floor.png')
floor_sprite:setPos(- 1024 / 2 + x, 768 / 2 - y)
layer:add(floor_sprite)

boxes = {}
for i = 1, 15 do
    for j = 1, 12 do
        local box = LakshmiBox2DBox.new(15, 15)
        box:setBodyType(LakshmiBox2DWorld.BODY_TYPE_DYNAMIC)
        box:setPos(50 + 65 * (i - 1), 50 + 55 * (j - 1))
        box:setRot(math.random() * 360)
        box:setFriction(0.6)
        box:setRestitution(0.5)

        local x, y = box:getPos()
        local r = box:getRot()
        local sprite = LakshmiSprite.new('test/box2d/crate.png')
        sprite:setPos(- 1024 / 2 + x, 768 / 2 - y)
        sprite:setRot(r)
        layer:add(sprite)

        table.insert(boxes, {box = box, sprite = sprite})
    end
end

LakshmiWindow.setLoopCallback(function(delta)
    LakshmiBox2DWorld.update(delta)

    for _, v in ipairs(boxes) do
        local x, y = v.box:getPos()
        v.sprite:setPos(- 1024 / 2 + x, 768 / 2 - y)
        v.sprite:setRot(v.box:getRot())
    end
end)
