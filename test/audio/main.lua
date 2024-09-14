LakshmiWindow.open('Lakshmi', 1024, 768)
LakshmiWindow.setVsync(true)
LakshmiRenderer.setClearColor(0.3, 0.3, 0.3, 1.0)

LakshmiKeyboard.setCallback(function(key, action)
    if action == LakshmiKeyboard.KEY_PRESS_ACTION and key == LakshmiKeyboard.KEY_ESCAPE then
        LakshmiAudioSystem.clear()
        LakshmiAudioSystem.destroy()

        LakshmiKeyboard.clearCallback()

        LakshmiWindow.quit()
    end
end)

LakshmiAudioSystem.init()

channels = {}

channels['music'] = LakshmiAudioChannel.new(true)
channels['voice'] = LakshmiAudioChannel.new()
channels['sound'] = LakshmiAudioChannel.new()

LakshmiAudioSystem.add(channels['music'])
LakshmiAudioSystem.add(channels['voice'])
LakshmiAudioSystem.add(channels['sound'])

channels['music']:setVolume(0.6)
channels['voice']:setPan(-1.0)
channels['sound']:setPan(1.0)

channels['music']:add('music', 'test/audio/music.ogg')
channels['voice']:add('voice', 'test/audio/voice.wav')
channels['sound']:add('sound', 'test/audio/sound.wav')

channels['voice']:play('voice')

frames = 0
LakshmiWindow.setLoopCallback(function(delta)
    frames = frames + 1

    if frames == 30 then
        channels['music']:play('music')
        channels['music']:setLoop(true)
    end

    if frames % (60 * 4) == 0 then
        channels['sound']:play('sound')
    end
end)
