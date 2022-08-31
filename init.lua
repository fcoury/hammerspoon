hs.loadSpoon('SpoonInstall')
spoon.SpoonInstall.use_syncinstall = true
Install = spoon.SpoonInstall

log = hs.logger.new('init', 5)

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
  win:move(f, screen, true, 0)
end)

hs.hotkey.bind({"cmd", "alt", "ctrl"}, "V", function()
  local win = hs.window.focusedWindow()
  local f = win:frame()
  local screen = win:screen()
  local max = screen:frame()

  local w = max.w*0.6
  local h = max.h*0.6

  f.x = max.w/2 - w/2
  f.y = max.h/2 - h/2
  f.w = w
  f.h = h
  win:setFrame(f, 0)
end)

hs.hotkey.bind({"cmd", "alt", "ctrl"}, "N", function()

end)

hs.hotkey.bind({"cmd", "alt"}, "V", function() hs.eventtap.keyStrokes(hs.pasteboard.getContents()) end)

-- Sidecar config
-- From here: https://gist.github.com/nriley/f2dfb2955836462b8f7806ce0da76bfb?permalink_comment_id=4280822#gistcomment-4280822

function systemPreferencesApplicationElement()
  local spApp
  spApp = hs.application.find('com.apple.systempreferences')
  if spApp then
    return hs.axuielement.applicationElement(spApp)
  else
    return nil
  end
end

function connectToSidecar(msg, results, count)
  local item

  sidecarItemFound = (count > 0)

  if not sidecarItemFound then
    return log:d("Can't get Sidecar connection menu item:", msg)
  end
  -- first item may be Universal Control
  if count == 2 then
    item = results[2]
  else
    item = results[1]
  end
  if item.AXMenuItemMarkChar == nil then
    log:d("Connecting to Sidecar...")
    item:doAXPress()
  else
    log:d("Closing menu - already connected to Sidecar...")
    item.AXParent:doAXCancel()
  end
  hs.application.find('com.apple.systempreferences'):kill()
end

function stopConnectToSidecarItemSearchTimer()
  if connectToSidecarItemSearchTimer then
    connectToSidecarItemSearchTimer:stop()
    connectToSidecarItemSearchTimer = nil
  end
end

function addDisplayMenu(msg, results, count)
  local menu, connectToSneezerItemSearch

  if count == 0 then
    return log:d("Can't find Add Display menu:", msg)
  end
  menu = results[1]
  menu:doAXPress()

  connectToSidecarItemCriteria = hs.axuielement.searchCriteriaFunction({
      {attribute = 'AXRole',       value = 'AXMenuItem'},
      {attribute = 'AXIdentifier', value = 'menuAction:'},
      {attribute = 'AXTitle',      value = 'Felipe...', pattern = true}})

  -- iPad may not appear immediately
  -- wait up to 3 seconds for it to appear
  stopConnectToSidecarItemSearchTimer()
  sidecarItemFound = false
  connectToSidecarItemSearchTimer = hs.timer.doUntil(
    function()
      return sidecarItemFound
    end,
    function()
      menu:elementSearch(connectToSidecar, connectToSidecarItemCriteria,
                         {count = 2, depth = 2, noCallback = true})
    end,
    0.5)
  hs.timer.doAfter(3, stopConnectToSidecarItemSearchTimer)
end

function stopSystemPreferencesSearchTimer()
  if systemPreferencesSearchTimer then
    systemPreferencesSearchTimer:stop()
    systemPreferencesSearchTimer = nil
  end
end

function connectSidecar()
  hs.urlevent.openURL("file:///System/Library/PreferencePanes/Displays.prefPane")
  addDisplayMenuCriteria = hs.axuielement.searchCriteriaFunction({
    {attribute = 'AXRole', value = 'AXPopUpButton'},
    {attribute = 'AXTitle', value = 'Add Display'}
  })
  spAX = nil
  addDisplayMenuSearch = nil
  systemPreferencesSearchTimer = hs.timer.doUntil(
    function()
      return spAX ~= nil and addDisplayMenuSearch and addDisplayMenuSearch:matched() > 0
    end,
    function()
      if addDisplayMenuSearch and addDisplayMenuSearch:isRunning() then
        return
      end
      spAX = systemPreferencesApplicationElement()
      if spAX ~= nil then
        log:d("Searching for Add Displays menu")
        addDisplayMenuSearch = spAX:elementSearch(addDisplayMenu, addDisplayMenuCriteria,
                                                  {count = 1, depth = 2})
      end
    end,
    0.5)
  hs.timer.doAfter(3, stopSystemPreferencesSearchTimer)
end

-- what we actually get when the iPad connects:
-- connect, disconnect, connect
-- ...but then we can't connect without triggering a timeout
-- so, wait 5 seconds
connectSidecarTimer = hs.timer.delayed.new(5, function()
  connectSidecar()
end)

function iPadConnected(connected)
  log:d("iPad connected?", connected)
  if connected then
    connectSidecarTimer:start()
  else
    connectSidecarTimer:stop()
  end
end

Install:andUse(
  "USBDeviceActions",
  {
    config = {
      devices = {
        iPad = { fn = iPadConnected }
      }
    },
    start = true
  }
)

hs.loadSpoon("ReloadConfiguration")
spoon.ReloadConfiguration:start()
