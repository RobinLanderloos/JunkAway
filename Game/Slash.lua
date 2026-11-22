-- /junkaway and /ja.
local addonName, ns = ...
local L = ns.L

local function say(text)
  print("|cffd9a066" .. addonName .. ":|r " .. text)
end
ns.Say = say

SLASH_JUNKAWAY1 = "/junkaway"
SLASH_JUNKAWAY2 = "/ja"
SlashCmdList.JUNKAWAY = function(message)
  local command, rest = (message or ""):match("^%s*(%S*)%s*(.-)%s*$")
  command = (command or ""):lower()
  if command == "" or command == "show" then
    ns.Window.Toggle()
  elseif command == "ignore" or command == "unignore" then
    local itemID = ns.IgnoreList.ItemID(rest)
    if not itemID then return say(L.NEED_ITEM) end
    local label = rest:find("|H", 1, true) and rest or ns.Game.ItemName(itemID)
    if command == "ignore" then
      ns.Window.Ignore(itemID)
      say(L.NOW_IGNORED:format(label))
    else
      ns.Window.Unignore(itemID)
      say(L.NO_LONGER_IGNORED:format(label))
    end
  elseif command == "options" or command == "config" then
    ns.OpenOptions()
  elseif command == "debug" then
    ns.Report.Debug()
  else
    say(L.SLASH_HELP)
  end
end
