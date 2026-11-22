-- Saved variables and the events that keep the window up to date.
local addonName, ns = ...

local events = CreateFrame("Frame")
local refreshQueued = false

-- Many bag and item events can arrive in one frame: rank once, a moment later.
local function queueRefresh()
  if refreshQueued then return end
  refreshQueued = true
  C_Timer.After(0.1, function()
    refreshQueued = false
    ns.Main.Update()
  end)
end

ns.Main = { QueueRefresh = queueRefresh }

function ns.Main.Update()
  if ns.Window.IsShown() then ns.Window.Refresh() end
end

events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("BAG_UPDATE_DELAYED")
events:RegisterEvent("GET_ITEM_INFO_RECEIVED")
events:SetScript("OnEvent", function(_, event, arg1)
  if event == "ADDON_LOADED" then
    if arg1 ~= addonName then return end
    if type(JunkAwayDB) ~= "table" then JunkAwayDB = {} end
    ns.db = JunkAwayDB
    ns.db.settings = ns.Settings.Normalize(ns.db.settings)
    if type(ns.db.ignore) ~= "table" then ns.db.ignore = {} end
    ns.settings = ns.db.settings
  elseif event == "BAG_UPDATE_DELAYED" then
    queueRefresh()
  elseif event == "GET_ITEM_INFO_RECEIVED" then
    if ns.Game.waitingForItems then queueRefresh() end
  end
end)
