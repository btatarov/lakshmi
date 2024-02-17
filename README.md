# Lakshmi

Lakshmi is an OpenGL 2D game engine with Lua scripting written in Odin. Work in progress.

## Lua API

List of available functions:

* LakshmiWindow.open(title, width, height)
* LakshmiWindow.setVsync(vsync)
* LakshmiSprite.new(path)
* LakshmiSprite.getPos(sprite)
* LakshmiSprite.getRot(sprite)
* LakshmiSprite.getScl(sprite)
* LakshmiSprite.setPos(sprite, x, y)
* LakshmiSprite.setRot(sprite, angle)
* LakshmiSprite.setScl(sprite, x, y)
* LakshmiRenderer.add(sprite)
* LakshmiRenderer.setClearColor(r, g, b, a)
* LakshmiJSON.decode(json_string)
* LakshmiJSON.encode(lua_table)
