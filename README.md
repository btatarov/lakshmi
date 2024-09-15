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

### Renderer

* LakshmiRenderer.add(layer)
* LakshmiRenderer.clear()
* LakshmiRenderer.setClearColor(r, g, b, a)

### Camera

* LakshmiCamera.setPos(x, y)
* LakshmiCamera.setRot(angle)

### Layer

* LakshmiLayer.new()
* LakshmiLayer.add(renderable, type)
* LakshmiLayer.clear()
* LakshmiLayer.setVisible(visible)

### Sprite

* LakshmiSprite.new(path)
* LakshmiSprite.getPos(sprite)
* LakshmiSprite.getRot(sprite)
* LakshmiSprite.getScl(sprite)
* LakshmiSprite.setPos(sprite, x, y)
* LakshmiSprite.setRot(sprite, angle)
* LakshmiSprite.setScl(sprite, x, y)
* LakshmiSprite.setVisible(sprite, visible)

### Text

* LakshmiText.new(font_path, text, size)
* LakshmiText.getPos(text)
* LakshmiText.setPos(text, x, y)
* LakshmiText.setVisible(text, visible)

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

* LakshmiBox2DEntity.new(primitive, sensor)
* LakshmiBox2DEntity.enable(box)
* LakshmiBox2DEntity.disable(box)
* LakshmiBox2DEntity.isEnabled(box)
* LakshmiBox2DEntity.isBullet(box)
* LakshmiBox2DEntity.applyForce(box, x_force, y_force, x_point, y_point)
* LakshmiBox2DEntity.applyLinearImpulse(box, x_impulse, y_impulse, x_point, y_point)
* LakshmiBox2DEntity.applyAngularImpulse(box, impulse)
* LakshmiBox2DEntity.applyTorque(box, torque)
* LakshmiBox2DEntity.getPos(box)
* LakshmiBox2DEntity.getRot(box)
* LakshmiBox2DEntity.getFriction(box)
* LakshmiBox2DEntity.getRestitution(box)
* LakshmiBox2DEntity.getLinearVelocity(box)
* LakshmiBox2DEntity.getAngularVelocity(box)
* LakshmiBox2DEntity.getBodyType(box)
* LakshmiBox2DEntity.setBullet(box, bullet)
* LakshmiBox2DEntity.setPos(box, x, y)
* LakshmiBox2DEntity.setRot(box, angle)
* LakshmiBox2DEntity.setFriction(box, friction)
* LakshmiBox2DEntity.setRestitution(box, restitution)
* LakshmiBox2DEntity.setLinearVelocity(box, x, y)
* LakshmiBox2DEntity.setAngularVelocity(box, angle)
* LakshmiBox2DEntity.setBodyType(box, body_type)
* LakshmiBox2DEntity.setCollisionCallback(box, callback)
* LakshmiBox2DEntity.clearCollisionCallback(box)

### Keyboard

* LakshmiKeyboard.clearCallback()
* LakshmiKeyboard.setCallback(callback)

### Audio

#### System

* LakshmiAudioSystem.init()
* LakshmiAudioSystem.destroy()
* LakshmiAudioSystem.add(channel)
* LakshmiAudioSystem.clear()

#### Channel

* LakshmiAudioChannel.new(is_streamed)
* LakshmiAudioChannel.add(channel, name, path)
* LakshmiAudioChannel.play(channel, name)
* LakshmiAudioChannel.pause(channel)
* LakshmiAudioChannel.stop(channel)
* LakshmiAudioChannel.setVolume(channel, volume)
* LakshmiAudioChannel.setPan(channel, pan)
* LakshmiAudioChannel.setLoop(channel, loop)
* LakshmiAudioChannel.clear(channel)

### JSON

* LakshmiJSON.decode(json_string)
* LakshmiJSON.encode(lua_table)
