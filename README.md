# Lakshmi

Lakshmi is an OpenGL 2D game engine with Lua scripting written in Odin. Work in progress.

## Lua API

List of available functions:

### Window

* LakshmiWindow.open(title, width, height)
* LakshmiWindow.clearLoopCallback()
* LakshmiWindow.setLoopCallback(callback)
* LakshmiWindow.setVsync(vsync)
* LakshmiWindow.quit()

### Sprite

* LakshmiSprite.new(path)
* LakshmiSprite.getPos(sprite)
* LakshmiSprite.getRot(sprite)
* LakshmiSprite.getScl(sprite)
* LakshmiSprite.setPos(sprite, x, y)
* LakshmiSprite.setRot(sprite, angle)
* LakshmiSprite.setScl(sprite, x, y)
* LakshmiSprite.setVisible(sprite, visible)

### Layer

* LakshmiLayer.new()
* LakshmiLayer.add(sprite)
* LakshmiLayer.clear()
* LakshmiLayer.setVisible(visible)

### Renderer

* LakshmiRenderer.add(layer)
* LakshmiRenderer.clear()
* LakshmiRenderer.setClearColor(r, g, b, a)

### Camera

* LakshmiCamera.setPos(x, y)
* LakshmiCamera.setRot(angle)

### Box2D

#### World

* LakshmiBox2DWorld.init()
* LakshmiBox2DWorld.destroy()
* LakshmiBox2DWorld.update(dt)
* LakshmiBox2DWorld.setGravity(x, y)
* LakshmiBox2DWorld.setUnitsPerMeter(upm)
* LakshmiBox2DWorld.setUpdateSteps(steps)

#### Box

* LakshmiBox2DBox.new(width, height, radius)

#### Capsule

* LakshmiBox2DCapsule.new(radius, x1, y1, x2, y2)

#### Circle

* LakshmiBox2DCircle.new(radius)

#### Polygon

* LakshmiBox2DPolygon.new(vertices, radius)

#### Entity

* LakshmiBox2DEntity.new(primitive)
* LakshmiBox2DEntity.getPos(box)
* LakshmiBox2DEntity.getRot(box)
* LakshmiBox2DEntity.getFriction(box)
* LakshmiBox2DEntity.getRestitution(box)
* LakshmiBox2DEntity.getLinearVelocity(box)
* LakshmiBox2DEntity.getAngularVelocity(box)
* LakshmiBox2DEntity.setPos(box, x, y)
* LakshmiBox2DEntity.setRot(box, angle)
* LakshmiBox2DEntity.setFriction(box, friction)
* LakshmiBox2DEntity.setRestitution(box, restitution)
* LakshmiBox2DEntity.setLinearVelocity(box, x, y)
* LakshmiBox2DEntity.setAngularVelocity(box, angle)
* LakshmiBox2DEntity.setBodyType(box, body_type)

### Keyboard

* LakshmiKeyboard.clearCallback()
* LakshmiKeyboard.setCallback(callback)

### JSON

* LakshmiJSON.decode(json_string)
* LakshmiJSON.encode(lua_table)
