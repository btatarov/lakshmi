print('Hello, 世界')
LakshmiWindow.open('Lakshmi', 1024, 768)

sprite1 = LakshmiSprite.new('test/lakshmi.png')
LakshmiRenderer.add(sprite1)

sprite2 = LakshmiSprite.new('test/lakshmi.png')
sprite2:setPos(1, 1)
LakshmiRenderer.add(sprite2)
