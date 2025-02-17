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

text = LakshmiText.new('test/text/unitblock.ttf', 'Hello, World!', 72)
text:setPos(0, 768 / 2 - 100)
text:setColor(1, 1, 0, 0.5)
text:setRot(30)
layer:add(text)
