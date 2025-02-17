# Lakshmi

Lakshmi is an OpenGL 2D game engine with Box2D physics and Lua scripting. Written in Odin. Work in progress.

## Lua API

List of available functions:

### Window

* LakshmiWindow.open(title, width, height)
* LakshmiWindow.clearLoopCallback()
* LakshmiWindow.clearResizeCallback()
* LakshmiWindow.getDeltaTime()
* LakshmiWindow.getDrawCount()
* LakshmiWindow.setLoopCallback(callback)
* LakshmiWindow.setResizeCallback(callback)
* LakshmiWindow.setTargetFPS(fps)
* LakshmiWindow.setVsync(vsync)
* LakshmiWindow.quit()

### Renderer

* LakshmiRenderer.add(layer)
* LakshmiRenderer.clear()
* LakshmiRenderer.getSpriteCount()
* LakshmiRenderer.setClearColor(r, g, b, a)

### Camera

* LakshmiCamera.setPos(x, y)
* LakshmiCamera.setRot(angle)

### Layer

* LakshmiLayer.new()
* LakshmiLayer.add(renderable)
* LakshmiLayer.clear()
* LakshmiLayer.setVisible(visible)

### Sprite

* LakshmiSprite.new(path)
* LakshmiSprite.getColor(sprite)
* LakshmiSprite.getPiv(sprite)
* LakshmiSprite.getPos(sprite)
* LakshmiSprite.getRot(sprite)
* LakshmiSprite.getScl(sprite)
* LakshmiSprite.getSize(sprite)
* LakshmiSprite.getUV(sprite)
* LakshmiSprite.isVisible(sprite)
* LakshmiSprite.setColor(sprite, r, g, b, a)
* LakshmiSprite.setPiv(sprite, x, y)
* LakshmiSprite.setPos(sprite, x, y)
* LakshmiSprite.setRot(sprite, angle)
* LakshmiSprite.setScl(sprite, x, y)
* LakshmiSprite.setSize(sprite, w, h)
* LakshmiSprite.setUV(sprite, u, v, w, h)
* LakshmiSprite.setVisible(sprite, visible)

### Text

* LakshmiText.new(font_path, text, size)
* LakshmiText.getColor(text)
* LakshmiText.getPiv(text)
* LakshmiText.getPos(text)
* LakshmiText.isVisible(text)
* LakshmiText.setColor(text, r, g, b, a)
* LakshmiText.setPiv(text, x, y)
* LakshmiText.setPos(text, x, y)
* LakshmiText.setVisible(text, visible)

### Box2D

#### World

* LakshmiBox2DWorld.init()
* LakshmiBox2DWorld.destroy()
* LakshmiBox2DWorld.getBodyCount()
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
* LakshmiBox2DEntity.enable(entity)
* LakshmiBox2DEntity.disable(entity)
* LakshmiBox2DEntity.isEnabled(entity)
* LakshmiBox2DEntity.isBullet(entity)
* LakshmiBox2DEntity.applyForce(entity, x_force, y_force, x_point, y_point)
* LakshmiBox2DEntity.applyLinearImpulse(entity, x_impulse, y_impulse, x_point, y_point)
* LakshmiBox2DEntity.applyAngularImpulse(entity, impulse)
* LakshmiBox2DEntity.applyTorque(entity, torque)
* LakshmiBox2DEntity.getPos(entity)
* LakshmiBox2DEntity.getRot(entity)
* LakshmiBox2DEntity.getFriction(entity)
* LakshmiBox2DEntity.getRestitution(entity)
* LakshmiBox2DEntity.getLinearVelocity(entity)
* LakshmiBox2DEntity.getAngularVelocity(entity)
* LakshmiBox2DEntity.getCategoryBits(entity)
* LakshmiBox2DEntity.getMaskBits(entity)
* LakshmiBox2DEntity.getBodyType(entity)
* LakshmiBox2DEntity.getUniqueID(entity)
* LakshmiBox2DEntity.setBullet(entity, bullet)
* LakshmiBox2DEntity.setPos(entity, x, y)
* LakshmiBox2DEntity.setRot(entity, angle)
* LakshmiBox2DEntity.setFriction(entity, friction)
* LakshmiBox2DEntity.setRestitution(entity, restitution)
* LakshmiBox2DEntity.setLinearVelocity(entity, x, y)
* LakshmiBox2DEntity.setAngularVelocity(entity, angle)
* LakshmiBox2DEntity.setCategoryBits(entity, category_bits)
* LakshmiBox2DEntity.setMaskBits(entity, mask_bits)
* LakshmiBox2DEntity.setBodyType(entity, body_type)
* LakshmiBox2DEntity.setCollisionCallback(entity, callback)
* LakshmiBox2DEntity.clearCollisionCallback(entity)

### Keyboard

* LakshmiKeyboard.clearCallback()
* LakshmiKeyboard.setCallback(callback)

### Gamepad

* LakshmiGamepad.isPresent()
* LakshmiGamepad.clearCallback()
* LakshmiGamepad.setCallback(callback)

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

## License

This project is licensed under the Apache 2.0 License. For more information, see the [LICENSE](LICENSE) file.


## Maintainers

- [Bogdan Tatarov](https://github.com/btatarov)
