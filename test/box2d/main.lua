math.randomseed(os.time())

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

floor_box = LakshmiBox2DBox.new(700, 35)
floor = LakshmiBox2DEntity.new(floor_box)
floor:setBodyType(LakshmiBox2DWorld.BODY_TYPE_STATIC)
floor:setPos(0, - 768 / 2 + 35)

x, y = floor:getPos()
floor_sprite = LakshmiSprite.new('test/box2d/floor.png')
floor_sprite:setPos(x, y)
layer:add(floor_sprite)

entities = {}
for i = 1, 15 do
    for j = 1, 12 do

        local box = nil
        local sprite = nil

        local random_pick = math.random(1, 2)
        if random_pick == 1 then
            box = LakshmiBox2DBox.new(15, 15)
        else
            box = LakshmiBox2DCircle.new(15)
        end

        local crate = LakshmiBox2DEntity.new(box)
        crate:setBodyType(LakshmiBox2DWorld.BODY_TYPE_DYNAMIC)
        crate:setPos(- 1024 / 2 + 50 + 65 * (i - 1), 768 / 2 - (50 + 55 * (j - 1)))
        crate:setRot(math.random() * 360)
        crate:setFriction(0.6)
        crate:setRestitution(0.5)

        if random_pick == 1 then
            sprite = LakshmiSprite.new('test/box2d/crate.png')
        else
            sprite = LakshmiSprite.new('test/box2d/ball.png')
        end
        sprite:setPos(crate:getPos())
        sprite:setRot(crate:getRot())
        layer:add(sprite)

        table.insert(entities, {entity = crate, sprite = sprite})
    end
end

frames = 0
LakshmiWindow.setLoopCallback(function(delta)
    LakshmiBox2DWorld.update(delta)

    for _, entity in ipairs(entities) do
        entity.sprite:setPos(entity.entity:getPos())
        entity.sprite:setRot(entity.entity:getRot())
    end

    frames = frames + 1
    if frames == 60 * 3 then
        for i = 1, 10 do
            entity = entities[math.random(1, #entities)]
            entity.entity:setLinearVelocity(math.random(-10, 10) * 1000, math.random(-10, 10) * 1000)
            entity.entity:setAngularVelocity(math.random(-10, 10) * 10)
        end
    end
end)
