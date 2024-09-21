-- window test
LakshmiWindow.open('Lakshmi', 1024, 768)
LakshmiWindow.setVsync(true)
LakshmiRenderer.setClearColor(0.3, 0.3, 0.3, 1.0)

layer = LakshmiLayer.new()
LakshmiRenderer.add(layer)

sprite = LakshmiSprite.new('test/sprites/lakshmi.png')
layer:add(sprite)

camera_directions = {
    up = false,
    down = false,
    left = false,
    right = false
}

camera_rotations = {
    left = false,
    right = false
}

LakshmiKeyboard.setCallback(function(key, action)
    if action == LakshmiKeyboard.KEY_PRESS_ACTION and key == LakshmiKeyboard.KEY_ESCAPE then
        LakshmiKeyboard.clearCallback()
        LakshmiWindow.quit()
    end

    if action == LakshmiKeyboard.KEY_PRESS_ACTION then
        if key == LakshmiKeyboard.KEY_W then
            camera_directions.up = true
        end
        if key == LakshmiKeyboard.KEY_S then
            camera_directions.down = true
        end
        if key == LakshmiKeyboard.KEY_A then
            camera_directions.left = true
        end
        if key == LakshmiKeyboard.KEY_D then
            camera_directions.right = true
        end
        if key == LakshmiKeyboard.KEY_LEFT_BRACKET then
            camera_rotations.left = true
        end
        if key == LakshmiKeyboard.KEY_RIGHT_BRACKET then
            camera_rotations.right = true
        end
    elseif action == LakshmiKeyboard.KEY_RELEASE_ACTION then
        if key == LakshmiKeyboard.KEY_W then
            camera_directions.up = false
        end
        if key == LakshmiKeyboard.KEY_S then
            camera_directions.down = false
        end
        if key == LakshmiKeyboard.KEY_A then
            camera_directions.left = false
        end
        if key == LakshmiKeyboard.KEY_D then
            camera_directions.right = false
        end
        if key == LakshmiKeyboard.KEY_LEFT_BRACKET then
            camera_rotations.left = false
        end
        if key == LakshmiKeyboard.KEY_RIGHT_BRACKET then
            camera_rotations.right = false
        end
    end
end)

move_speed = 100
LakshmiWindow.setLoopCallback(function(delta)
    local x, y = LakshmiCamera.getPos()
    if camera_directions.up then
        y = y - move_speed * delta
    end
    if camera_directions.down then
        y = y + move_speed * delta
    end
    if camera_directions.left then
        x = x + move_speed * delta
    end
    if camera_directions.right then
        x = x - move_speed * delta
    end
    LakshmiCamera.setPos(x, y)

    local r = LakshmiCamera.getRot()
    if camera_rotations.left then
        r = r - 90 * delta
    end
    if camera_rotations.right then
        r = r + 90 * delta
    end
    LakshmiCamera.setRot(r)
end)
