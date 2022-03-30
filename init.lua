hs.hotkey.bind({"cmd", "alt", "ctrl"}, "C", function()
  local win = hs.window.focusedWindow()
  local f = win:frame()
  local screen = win:screen()
  local max = screen:frame()

  local w = max.w*0.8
  local h = max.h*0.8

  f.x = max.w/2 - w/2
  f.y = max.h/2 - h/2
  f.w = w
  f.h = h
  win:setFrame(f, 0)
end)

hs.hotkey.bind({"cmd", "alt"}, "V", function() hs.eventtap.keyStrokes(hs.pasteboard.getContents()) end)

hs.loadSpoon("ReloadConfiguration")
spoon.ReloadConfiguration:start()
