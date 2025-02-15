LakshmiWindow.open('Lakshmi', 1024, 768)
LakshmiWindow.setVsync(true)
LakshmiRenderer.setClearColor(0.3, 0.3, 0.3, 1.0)

layer = LakshmiLayer.new()
LakshmiRenderer.add(layer)

sprite1 = LakshmiSprite.new('test/sprites/lakshmi.png')
sprite1:setPos(-150, 150)

sprite2 = LakshmiSprite.new('test/sprites/meditate.png')
sprite2:setPos(150, -150)
x, y = sprite2:getSize()
sprite2:setPiv(- x / 2, y / 2)

layer:add(sprite1)
layer:add(sprite2)

LakshmiKeyboard.setCallback(function(key, action)
    if action == LakshmiKeyboard.KEY_PRESS_ACTION and key == LakshmiKeyboard.KEY_ESCAPE then
        LakshmiKeyboard.clearCallback()
        LakshmiWindow.quit()
    end

    if action == LakshmiKeyboard.KEY_PRESS_ACTION and key == LakshmiKeyboard.KEY_UP then
        local x, y = sprite1:getScl()
        sprite1:setScl(x + 0.1, y + 0.1)
        x, y = sprite2:getScl()
        sprite2:setScl(x + 0.1, y + 0.1)
    end

    if action == LakshmiKeyboard.KEY_PRESS_ACTION and key == LakshmiKeyboard.KEY_DOWN then
        local x, y = sprite1:getScl()
        sprite1:setScl(x - 0.1, y - 0.1)
        x, y = sprite2:getScl()
        sprite2:setScl(x - 0.1, y - 0.1)
    end

    if action == LakshmiKeyboard.KEY_PRESS_ACTION and key == LakshmiKeyboard.KEY_LEFT then
        local rot = sprite1:getRot()
        sprite1:setRot(rot + 10)
        rot = sprite2:getRot()
        sprite2:setRot(rot + 10)
    end

    if action == LakshmiKeyboard.KEY_PRESS_ACTION and key == LakshmiKeyboard.KEY_RIGHT then
        local rot = sprite1:getRot()
        sprite1:setRot(rot - 10)
        rot = sprite2:getRot()
        sprite2:setRot(rot - 10)
    end
end)
