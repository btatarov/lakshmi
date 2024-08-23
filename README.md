# Lakshmi

Lakshmi is an OpenGL 2D game engine with Lua scripting written in Odin. Work in progress.

## Lua API

List of available functions:

### Window

* LakshmiWindow.open(title, width, height)
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

### Keyboard

* LakshmiKeyboard.clearCallback()
* LakshmiKeyboard.setCallback(callback)

### JSON

* LakshmiJSON.decode(json_string)
* LakshmiJSON.encode(lua_table)
