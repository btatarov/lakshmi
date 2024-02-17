-- hello world
print('Hello, 世界')

-- json test
json = [[
{
    "name": "Lakshmi",
    "version": 0.1,
    "build": 1,
    "development": true,
    "released": false,
    "keywords": [
        "engine",
        "odin",
        "lua"
    ],
    "contributors": {
        "main": "Bogdan Tatarov"
    }
}
]]

data = LakshmiJSON.decode(json)
print(data.name)
print(data.version)
print(data.build)
for i, v in ipairs(data.keywords) do
    print(i, v)
end
for k, v in pairs(data.contributors) do
    print(k, v)
end

json = LakshmiJSON.encode(data)
print(json)

-- window test
LakshmiWindow.open('Lakshmi', 1024, 768)
LakshmiWindow.setVsync(true)
LakshmiRenderer.setClearColor(0.3, 0.3, 0.3, 1.0)

-- sprite/renderer test
sprite1 = LakshmiSprite.new('test/lakshmi.png')
sprite1:setPos(0, 0)
sprite1:setRot(0)
sprite1:setScl(1, 1)

sprite2 = LakshmiSprite.new('test/lakshmi.png')
sprite2:setPos(0.5, 0.5)
sprite2:setRot(-45)
sprite2:setScl(0.8, 0.8)
print('sprite2 pos:', sprite2:getPos())
print('sprite2 rot:', sprite2:getRot())
print('sprite2 scl:', sprite2:getScl())

LakshmiRenderer.add(sprite1)
LakshmiRenderer.add(sprite2)

-- stress test without texture cache and batch rendering
sprites = {}
for i = 1, 500 do
    sprites[i] = LakshmiSprite.new('test/lakshmi.png')
    sprites[i]:setPos(math.random() - 0.5, math.random() - 0.5)
    sprites[i]:setRot(math.random() * 360 - 180)
    scl = math.random() * 0.5 + 0.1
    sprites[i]:setScl(scl, scl)
    LakshmiRenderer.add(sprites[i])
end
