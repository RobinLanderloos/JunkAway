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
  local command = (message or ""):match("^%s*(%S*)") or ""
  command = command:lower()
  if command == "" or command == "show" then
    ns.Window.Toggle()
  else
    say(L.SLASH_HELP)
  end
end
