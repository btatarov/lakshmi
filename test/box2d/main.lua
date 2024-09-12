LakshmiWindow.open('Lakshmi', 1024, 768)
LakshmiWindow.setVsync(true)
LakshmiRenderer.setClearColor(0.3, 0.3, 0.3, 1.0)

LakshmiKeyboard.setCallback(function(key, action)
    if action == LakshmiKeyboard.KEY_PRESS_ACTION and key == LakshmiKeyboard.KEY_ESCAPE then
        LakshmiKeyboard.clearCallback()
        LakshmiWindow.quit()
    end
end)

LakshmiBox2DWorld.init()
LakshmiBox2DWorld.setUnitsPerMeter(10)
LakshmiBox2DWorld.setGravity(0, 9.80665)
LakshmiBox2DWorld.setUpdateSteps(8)

box = LakshmiBox2DBox.new(1024 / 2, 768 / 2, 50, 50, LakshmiBox2DWorld.BODY_TYPE_DYNAMIC)
box:setPos(100, 100)
box:setRot(35)

count = 0
LakshmiWindow.setLoopCallback(function(delta)
    LakshmiBox2DWorld.update(delta)
    print('box pos:', box:getPos())
    print('box rot:', box:getRot())

    if count > 10 then
        box:setBodyType(LakshmiBox2DWorld.BODY_TYPE_STATIC)
    else
        count = count + 1
    end
end)
