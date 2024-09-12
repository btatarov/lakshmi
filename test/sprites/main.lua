-- window test
LakshmiWindow.open('Lakshmi', 1024, 768)
LakshmiWindow.setVsync(true)
LakshmiRenderer.setClearColor(0.3, 0.3, 0.3, 1.0)

-- keyboard test
LakshmiKeyboard.setCallback(function(key, action)
    print('LakshmiKeyboard callback')
    print('key:', key, 'action:', action)
    if action == LakshmiKeyboard.KEY_PRESS_ACTION and key == LakshmiKeyboard.KEY_ESCAPE then
        LakshmiKeyboard.clearCallback()
        LakshmiWindow.quit()
    end
end)

-- camera test
LakshmiCamera.setPos(15, 15)
LakshmiCamera.setRot(30)
print('camera pos:', LakshmiCamera.getPos())
print('camera rot:', LakshmiCamera.getRot())

-- sprite/renderer test
layer = LakshmiLayer.new()
LakshmiRenderer.add(layer)

sprite1 = LakshmiSprite.new('test/sprites/lakshmi.png')
sprite1:setPos(-1024 / 2, 768 / 2)
sprite1:setRot(0)
sprite1:setScl(1, 1)

sprite2 = LakshmiSprite.new('test/sprites/meditate.png')
sprite2:setPos(250, 250)
sprite2:setRot(-45)
sprite2:setScl(0.8, 0.8)
print('sprite2 pos:', sprite2:getPos())
print('sprite2 rot:', sprite2:getRot())
print('sprite2 scl:', sprite2:getScl())

layer:add(sprite1)
layer:add(sprite2)

-- stress test
sprites = {}
for i = 1, 3000 do
    if i % 2 == 0 then
        sprites[i] = LakshmiSprite.new('test/sprites/lakshmi.png')
    else
        sprites[i] = LakshmiSprite.new('test/sprites/meditate.png')
    end
    sprites[i]:setPos(math.random() * 1024 - 1024 / 2, math.random() * 768 - 768 / 2)
    sprites[i]:setRot(math.random() * 360 - 180)
    scl = math.random() * 0.9 + 0.1
    sprites[i]:setScl(scl, scl)
    layer:add(sprites[i])

    if i % 3 == 0 then
        sprites[i]:setVisible(false)
    end
end

-- main loop test
count = 0
LakshmiWindow.setLoopCallback(function(delta)
    print('LakshmiWindow loop callback with delta:', delta)
    count = count + 1
    if count == 10 then
        LakshmiWindow.clearLoopCallback()
    end
end)
