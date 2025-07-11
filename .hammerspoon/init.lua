--- hs.alert.show('Hello, world!')

local inputEnglish = "com.apple.keylayout.ABC"
--- local inputEnglish = "com.apple.keylayout.Dvorak"
local inputKorean = "org.youknowone.inputmethod.Gureum.han2"

require('modules.inputsource_aurora')

function escape()
	local inputSource = hs.keycodes.currentSourceID()
    local inputEnglish = "com.apple.keylayout.UnicodeHexInput"

	if not (inputSource == inputEnglish) then
		hs.keycodes.currentSourceID(inputEnglish)
	end
	hs.eventtap.keyStroke({}, 'escape')
end

--- 현재 사용중인 키보드 이름 표시
hs.hotkey.bind({'option', 'control'}, 'i', function()
    local input_source = hs.keycodes.currentSourceID()
    print(input_source)
end)

--- ctrl + [ 키를 esc로 매핑 및 입력소스 변경
--- hs.hotkey.bind({'control'}, 33, escape)
--- hs.hotkey.bind({'cmd', 'control'}, 'delete', function()
---     hs.eventtap.keyStroke({'shift'}, 'end')
---     hs.eventtap.keyStroke({}, 'delete')
--- end)

function appLaunchOrFocus(name)
    return function()
        hs.application.launchOrFocus(name)
    end
end

function appLaunchOrFocusBundle(bundleID)
    return function()
        hs.application.launchOrFocusByBundleID(bundleID)
    end
end


--- quick open applications
--- https://zhiye.li/hammerspoon-use-the-keyboard-shortcuts-to-launch-apps-a7c59ab3d92
hs.hotkey.bind({"option", "control"}, "X", appLaunchOrFocus("Finder"))
hs.hotkey.bind({"option", "control"}, "N", appLaunchOrFocus("iTerm"))
hs.hotkey.bind({"option", "control"}, "E", appLaunchOrFocus("iTerm"))
-- hs.hotkey.bind({"option", "control"}, "D", appLaunchOrFocus("WezTerm"))
hs.hotkey.bind({"option", "control"}, ",", appLaunchOrFocus("Obsidian"))

--- hs.hotkey.bind({"option", "control"}, "I", appLaunchOrFocus("Intellij IDEA"))
--- hs.hotkey.bind({"option", "control"}, "M", appLaunchOrFocus("Visual Studio Code"))
--- hs.hotkey.bind({"option", "control"}, "Q", appLaunchOrFocus("Visual Studio Code"))
hs.hotkey.bind({"option", "control"}, "M", appLaunchOrFocus("Cursor"))
hs.hotkey.bind({"option", "control"}, "Q", appLaunchOrFocus("Cursor"))
--- hs.hotkey.bind({"option", "control"}, "A", appLaunchOrFocus("Cursor"))

--- hs.hotkey.bind({"option", "control"}, "W", appLaunchOrFocus("Safari"))
-- hs.hotkey.bind({"option", "control"}, "W", appLaunchOrFocus("Google Chrome"))
hs.hotkey.bind({"option", "control"}, "W", appLaunchOrFocus("Arcbrowser"))

--- hs.hotkey.bind({"option", "control"}, "Y", appLaunchOrFocus("Youtube"))

--- hs.hotkey.bind({"option", "control"}, "E", appLaunchOrFocus("Microsoft Excel"))
--- hs.hotkey.bind({"option", "control"}, "N", appLaunchOrFocus("Notion"))
--- hs.hotkey.bind({"option", "control"}, "W", appLaunchOrFocus("Microsoft Word"))
--- hs.hotkey.bind({"option", "control"}, "R", appLaunchOrFocus("Preview"))
--- hs.hotkey.bind({"option", "control"}, "P", appLaunchOrFocus("Microsoft PowerPoint"))

--- hs.hotkey.bind({"option", "control"}, "I", appLaunchOrFocus("Mail"))
--- hs.hotkey.bind({"option", "control"}, "O", appLaunchOrFocus("Microsoft Outlook"))

--- Messenger
hs.hotkey.bind({"option", "control"}, "Y", appLaunchOrFocus("AIWorks-Messenger"))

hs.hotkey.bind({"option", "control"}, "B", appLaunchOrFocus(os.getenv("HOME").."/Applications/Chrome Apps.localized/Messages.app"))
-- hs.hotkey.bind({"option", "control"}, "H", appLaunchOrFocusBundle("com.google.Chrome.app.hpfldicfbfomlpcikngkocigghgafkph"))
hs.hotkey.bind({"option", "control"}, "U", appLaunchOrFocus("DuelKakaoTalk"))
hs.hotkey.bind({"option", "control"}, "I", appLaunchOrFocus("KakaoTalk"))
hs.hotkey.bind({"option", "control"}, "O", appLaunchOrFocus("Discord"))
--- hs.hotkey.bind({"option", "control"}, "O", appLaunchOrFocus("Docker"))
--- hs.hotkey.bind({"option", "control"}, "S", appLaunchOrFocus("Slack"))
--- hs.hotkey.bind({"option", "control"}, "M", appLaunchOrFocus("Messages"))

hs.hotkey.bind({"option", "control"}, "B", appLaunchOrFocus("Beyond Compare"))
hs.hotkey.bind({"option", "control"}, "P", appLaunchOrFocus("Activity Monitor"))


hs.hotkey.bind({"option", "control"}, "6", appLaunchOrFocus("GrowCastle"))




function setVolumeZero()
    hs.audiodevice.defaultOutputDevice():setVolume(0)
end

wifiWatcher = hs.wifi.watcher.new(setVolumeZero)
wifiWatcher:start()

hs.audiodevice.defaultOutputDevice():setVolume(0)




hs.alert.show('loaded')
