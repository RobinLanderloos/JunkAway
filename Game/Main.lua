-- Saved variables, and the watcher: opens the window when the bags become
-- full and closes it again when there is room (docs/adr/0005).
local addonName, ns = ...

local Main = {}
ns.Main = Main

local events = CreateFrame("Frame")
local refreshQueued = false
local wasFull = nil   -- nil until the first look at the bags after login
local openAfterCombat = false

-- Many bag and item events can arrive in one frame: rank once, a moment later.
function Main.QueueRefresh()
  if refreshQueued then return end
  refreshQueued = true
  C_Timer.After(0.1, function()
    refreshQueued = false
    Main.Update()
  end)
end

function Main.Update()
  local r = ns.Game.Rank()
  if r.full and wasFull == false then
    if InCombatLockdown() then
      openAfterCombat = true
    else
      ns.Window.Show(true)
    end
  elseif not r.full then
    openAfterCombat = false
    if ns.Window.autoOpened and ns.Window.IsShown() then ns.Window.Hide() end
  end
  wasFull = r.full
  if ns.Window.IsShown() then ns.Window.Refresh(r) end
end

events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("BAG_UPDATE_DELAYED")
events:RegisterEvent("GET_ITEM_INFO_RECEIVED")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:SetScript("OnEvent", function(_, event, arg1)
  if event == "ADDON_LOADED" then
    if arg1 ~= addonName then return end
    if type(JunkAwayDB) ~= "table" then JunkAwayDB = {} end
    ns.db = JunkAwayDB
    ns.db.settings = ns.Settings.Normalize(ns.db.settings)
    if type(ns.db.ignore) ~= "table" then ns.db.ignore = {} end
    ns.settings = ns.db.settings
  elseif event == "BAG_UPDATE_DELAYED" then
    Main.QueueRefresh()
  elseif event == "GET_ITEM_INFO_RECEIVED" then
    if ns.Game.waitingForItems then Main.QueueRefresh() end
  elseif event == "PLAYER_REGEN_ENABLED" then
    if openAfterCombat then
      openAfterCombat = false
      if wasFull then ns.Window.Show(true) end
    end
  end
end)
