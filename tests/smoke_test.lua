-- Load check: runs every file the .toc lists, in order, against a small
-- stand-in for the game. Catches missing files, syntax errors and nil calls
-- before logging in; it does not prove the real client behaves the same.
--   luajit tests/smoke_test.lua
local ADDON = "JunkAway"

local files = {}
for line in io.lines(ADDON .. ".toc") do
  line = line:gsub("%s+$", "")
  if line ~= "" and not line:match("^#") then files[#files + 1] = (line:gsub("\\", "/")) end
end

-- Widgets: remember scripts, events, text, attributes, size, anchor and
-- shown state; Create* calls give child widgets. Like real frames, unknown
-- methods (capitalised) do nothing and unset fields are nil.
local widgets = {}
local function newWidget(parent)
  local w = { shown = true, scripts = {}, events = {}, parentWidget = parent }
  widgets[#widgets + 1] = w
  return setmetatable(w, { __index = function(self, key)
    if key == "Text" or key == "TitleText" then
      local child = newWidget(self); rawset(self, key, child); return child
    end
    if key == "SetScript" then return function(s, name, fn) s.scripts[name] = fn end end
    if key == "RegisterEvent" or key == "RegisterUnitEvent" then return function(s, name) s.events[name] = true end end
    if key == "UnregisterEvent" then return function(s, name) s.events[name] = nil end end
    if key == "SetText" then return function(s, text) rawset(s, "text", text) end end
    if key == "GetText" then return function(s) return rawget(s, "text") end end
    if key == "SetAttribute" then
      return function(s, name, v) rawset(s, "attrs", rawget(s, "attrs") or {}); s.attrs[name] = v end
    end
    if key == "SetAlpha" then return function(s, v) rawset(s, "alpha", v) end end
    if key == "SetChecked" then return function(s, v) rawset(s, "checked", v and true or false) end end
    if key == "GetChecked" then return function(s) return rawget(s, "checked") == true end end
    if key == "SetResizable" then return function(s, v) rawset(s, "resizable", v) end end
    if key == "GetParent" then return function(s) return rawget(s, "parentWidget") end end
    if key == "IsShown" then return function(s) return s.shown end end
    if key == "Show" then return function(s) s.shown = true; if s.scripts.OnShow then s.scripts.OnShow(s) end end end
    if key == "Hide" then return function(s) s.shown = false end end
    if key == "SetShown" then return function(s, v) if v then s:Show() else s:Hide() end end end
    if key == "SetSize" then return function(s, w2, h) rawset(s, "width", w2); rawset(s, "height", h) end end
    if key == "GetWidth" then return function(s) return rawget(s, "width") or 0 end end
    if key == "GetHeight" then return function(s) return rawget(s, "height") or 0 end end
    if key == "SetPoint" then
      return function(s, ...) if not rawget(s, "point") then rawset(s, "point", { ... }) end end
    end
    if key == "ClearAllPoints" then return function(s) rawset(s, "point", nil) end end
    if type(key) == "string" and key:match("^Create") then
      return function(s, name) local c = newWidget(s); if type(name) == "string" then rawset(c, "name", name) end; return c end
    end
    if type(key) == "string" and key:match("^%u") then return function() end end
    return nil
  end })
end

local function fire(event, ...)
  for _, w in ipairs(widgets) do
    if w.events[event] and w.scripts.OnEvent then w.scripts.OnEvent(w, event, ...) end
  end
end

-- Shown only when it and every parent are shown, as in the game.
local function visible(w)
  while w do
    if not rawget(w, "shown") then return false end
    w = rawget(w, "parentWidget")
  end
  return true
end

local function shownTexts()
  local texts = {}
  for _, w in ipairs(widgets) do
    local text = rawget(w, "text")
    if visible(w) and type(text) == "string" then texts[#texts + 1] = text end
  end
  return table.concat(texts, "\n")
end

local function find(predicate)
  for _, w in ipairs(widgets) do if predicate(w) then return w end end
end

-- Timers wait until the test runs them, as the game would on later frames.
local timers = {}
local function runTimers()
  local guard = 0
  while #timers > 0 and guard < 100000 do
    table.remove(timers, 1)()
    guard = guard + 1
  end
end


-- ------------------------------------------------------------------ game
-- Items: id = { name, quality, maxStack, sellPrice, classID }
local ITEMS = {
  [2589] = { "Linen Cloth", 1, 20, 13, 7 },
  [6948] = { "Hearthstone", 1, 1, 0, 15 },
  [2934] = { "Ruined Leather Scraps", 0, 10, 3, 7 },
  [15210] = { "Raider's Shortsword", 2, 1, 2500, 2 },
  [4306] = { "Silk Cloth", 1, 20, 150, 7 },
  [745] = { "Marshal McBride's Documents", 1, 1, 0, 12 },
  [2512] = { "Rough Arrow", 1, 200, 0, 6 },
}
local function link(id) return "|cffffffff|Hitem:" .. id .. "::::::::10|h[" .. ITEMS[id][1] .. "]|h|r" end
local function itemID(l) return tonumber(tostring(l):match("item:(%d+)")) end

-- Containers: containers[bag] = { slots = n, family = f, [slot] = { id, count, bound } }
local containers = {}
local function setBag(bag, size, items, fam)
  local c = { slots = size, family = fam or 0 }
  for i, it in pairs(items or {}) do c[i] = it end
  containers[bag] = c
end

_G.strmatch, _G.strfind, _G.strsub, _G.strlower, _G.strupper = string.match, string.find, string.sub, string.lower, string.upper
_G.format, _G.gsub, _G.strlen, _G.strtrim = string.format, string.gsub, string.len, function(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end
_G.tremove, _G.tinsert = table.remove, table.insert
_G.wipe = function(t) for k in pairs(t) do t[k] = nil end return t end

_G.Enum = { BagIndex = { Backpack = 0 } }
_G.NUM_BAG_SLOTS = 4
local pickedUp = {}
_G.C_Container = {
  GetContainerNumSlots = function(bag) return containers[bag] and containers[bag].slots or 0 end,
  GetContainerNumFreeSlots = function(bag)
    local c = containers[bag]
    if not c then return 0, 0 end
    local free = 0
    for i = 1, c.slots do if not c[i] then free = free + 1 end end
    return free, c.family
  end,
  GetContainerItemInfo = function(bag, slot)
    local it = containers[bag] and containers[bag][slot]
    if not it then return nil end
    return { hyperlink = link(it[1]), itemID = it[1], stackCount = it[2] or 1, iconFileID = 134400,
      isBound = it[3] or false, isLocked = false, quality = ITEMS[it[1]][2] }
  end,
  PickupContainerItem = function(bag, slot) pickedUp[#pickedUp + 1] = bag .. ":" .. slot end,
}
_G.C_Item = {
  GetItemInfo = function(l)
    local id = itemID(l)
    local n = ITEMS[id]
    if not n then return nil end
    return n[1], l, n[2], 10, 1, "", "", n[3], "", 134400, n[4], n[5], 0
  end,
}
local openedCategory
_G.Settings = {
  RegisterCanvasLayoutCategory = function(panel, name) return { panel = panel, name = name, GetID = function() return 77 end } end,
  RegisterAddOnCategory = function() end,
  OpenToCategory = function(id) openedCategory = id end,
}
_G.ITEM_QUALITY3_DESC, _G.ITEM_QUALITY4_DESC = "Rare", "Epic"
_G.C_CurrencyInfo = { GetCoinTextureString = function(c) return tostring(c) .. "c" end }
_G.hooksecurefunc = function() end
_G.CreateFrame = function(_, name, parent)
  local w = newWidget(parent)
  rawset(w, "name", name)
  if type(name) == "string" then _G[name] = w end
  return w
end
_G.UIParent = newWidget()
_G.GameTooltip = newWidget()
_G.UISpecialFrames = {}
_G.C_Timer = { After = function(_, fn) timers[#timers + 1] = fn end }
local inCombat = false
_G.InCombatLockdown = function() return inCombat end
_G.SlashCmdList = {}
_G.GetBuildInfo = function() return "1.60.1", "70938", "Nov 1 2026", 16001 end
_G.time = function() return 1763100000 end
_G.date = os.date

-- Backpack: 16 slots, 3 filled; bag 1 a quiver with arrows.
setBag(0, 16, { { 2589, 5 }, { 6948, 1, true }, { 2934, 2 }, [5] = { 15210, 1 } })
setBag(1, 8, { { 2512, 200 } }, 1)

local ns = {}
for _, file in ipairs(files) do
  local chunk, err = loadfile(file)
  if not chunk then error("the .toc lists a file that does not load: " .. tostring(err)) end
  chunk(ADDON, ns)
end
fire("ADDON_LOADED", ADDON)
fire("PLAYER_LOGIN")
runTimers()

local failed = 0
local function check(name, condition, detail)
  if not condition then
    failed = failed + 1
    print("FAIL  " .. name .. (detail and ("\n      " .. tostring(detail)) or ""))
  end
end

local said = {}
local realPrint = print
local function slash(message)
  said = {}
  _G.print = function(text) said[#said + 1] = tostring(text) end
  local ok, err = pcall(SlashCmdList.JUNKAWAY, message)
  _G.print = realPrint
  runTimers()
  return ok, ok and table.concat(said, "\n") or tostring(err)
end

local function rowFor(name)
  return find(function(w) return rawget(w, "fact") and not rawget(w, "merge") and visible(w) and rawget(w, "fact").name == name end)
end

-- ---------------------------------------------------------------- 001
local ok, out = slash("")
local win = _G.JunkAwayWindow
check("/ja opens the window", ok and win and visible(win), out)
local texts = shownTexts()
check("cheapest slot (scraps, 6c) is listed", rowFor("Ruined Leather Scraps") ~= nil, texts)
check("the Hearthstone (no price) is never listed", rowFor("Hearthstone") == nil, texts)
local scraps = rowFor("Ruined Leather Scraps")
if scraps then scraps.scripts.OnClick(scraps) end
check("clicking a row picks the item up", pickedUp[1] == "0:3", pickedUp[1])

-- ---------------------------------------------------------------- 004
local linen = rowFor("Linen Cloth")
check("rows have an Ignore button", linen and linen.ignore, texts)
if linen then linen.ignore.scripts.OnClick(linen.ignore) end
check("Ignore removes the item from the suggestions", rowFor("Linen Cloth") == nil, shownTexts())
check("and saves it account-wide", JunkAwayDB.ignore[2589] == true)
local modeB = find(function(w) return rawget(w, "text") == ns.L.IGNORED and visible(w) end)
check("an Ignored button shows", modeB ~= nil, shownTexts())
if modeB then modeB.scripts.OnClick(modeB) end
local ignoredRow = find(function(w) return rawget(w, "remove") and visible(w) and w.fact and w.fact.itemID == 2589 end)
check("Ignored mode lists linen", ignoredRow ~= nil, shownTexts())
if ignoredRow then ignoredRow.remove.scripts.OnClick(ignoredRow.remove) end
check("Remove un-ignores it", JunkAwayDB.ignore[2589] == nil)
local backB = find(function(w) return rawget(w, "text") == ns.L.BACK and visible(w) end)
if backB then backB.scripts.OnClick(backB) end
check("Back shows linen again", rowFor("Linen Cloth") ~= nil, shownTexts())
ok, out = slash("ignore " .. link(2589))
check("/ja ignore <link> ignores", ok and JunkAwayDB.ignore[2589] == true, out)
ok, out = slash("unignore 2589")
check("/ja unignore <id> un-ignores", ok and JunkAwayDB.ignore[2589] == nil, out)
ok, out = slash("ignore Silk")
check("/ja ignore <name> explains how", ok and out:find(ns.L.NEED_ITEM, 1, true), out)

ok, out = slash("")
check("/ja again closes the window", ok and not visible(win), out)

-- ---------------------------------------------------------------- 002
_G.Auctionator = { API = { v1 = {
  GetAuctionPriceByItemLink = function(_, l) if itemID(l) == 2934 then return 1000 end end,
  GetAuctionPriceByItemID = function() return nil end,
} } }
slash("")
local scrapsRow = rowFor("Ruined Leather Scraps")
check("Auctionator's price counts (scraps now 2 x 950c)", scrapsRow and scrapsRow.fact.value == 1900, shownTexts())
slash("")
_G.Auctionator = nil

-- ---------------------------------------------------------------- 005
fire("BAG_UPDATE_DELAYED"); runTimers()
check("the window stays shut while there is room", not visible(win))
local function fillBackpack(except)
  for i = 1, 16 do
    if not containers[0][i] and i ~= except then containers[0][i] = { 4306, 1 } end
  end
end
fillBackpack(16)
fire("BAG_UPDATE_DELAYED"); runTimers()
check("one free slot left: still shut (warn at 0)", not visible(win))
containers[0][16] = { 4306, 1 }
fire("BAG_UPDATE_DELAYED"); runTimers()
check("the window opens when the bags become full", visible(win))
check("the quiver's arrows are never listed", rowFor("Rough Arrow") == nil, shownTexts())
fire("BAG_UPDATE_DELAYED"); runTimers()
check("still open on the next bag change", visible(win))
containers[0][16] = nil
fire("BAG_UPDATE_DELAYED"); runTimers()
check("an auto-opened window closes when a slot frees up", not visible(win))

inCombat = true
containers[0][16] = { 4306, 1 }
fire("BAG_UPDATE_DELAYED"); runTimers()
check("in combat it waits", not visible(win))
inCombat = false
fire("PLAYER_REGEN_ENABLED"); runTimers()
check("and opens when combat ends", visible(win))

containers[0][16] = nil
fire("BAG_UPDATE_DELAYED"); runTimers()
slash("")
containers[0][16] = { 4306, 1 }
fire("BAG_UPDATE_DELAYED"); runTimers()
containers[0][16] = nil
fire("BAG_UPDATE_DELAYED"); runTimers()
check("a window opened with /ja stays open when room frees up", visible(win))
slash("")

-- ---------------------------------------------------------------- 006
slash("")
local mergeRow = find(function(w) return rawget(w, "merge") and visible(w) end)
check("partial Silk stacks give a merge row", mergeRow and mergeRow.label.text == "Merge Silk Cloth (1 + 1)",
  shownTexts())
pickedUp = {}
_G.C_Container.PickupContainerItem = function(bag, slot) pickedUp[#pickedUp + 1] = bag .. ":" .. slot end
if mergeRow then mergeRow.ignore.scripts.OnClick(mergeRow.ignore) end
check("Merge picks up one stack and drops it on the other", pickedUp[1] == "0:4" and pickedUp[2] == "0:15",
  table.concat(pickedUp, " "))
check("Merge doesn't ignore anything", next(JunkAwayDB.ignore) == nil)
local linenRow = rowFor("Linen Cloth")
check("a stack candidate says the whole stack goes", linenRow and linenRow.note.text == "Whole stack of 5",
  linenRow and linenRow.note.text)
slash("")

-- ---------------------------------------------------------------- 007
ok, out = slash("options")
check("/ja options opens the settings", ok and openedCategory == 77, out)
local opt = ns.Options
check("the settings panel is built", opt ~= nil)
if opt then
  opt.panel:Show()
  check("quality limit shows Epic", opt.quality.value.text == "Epic", opt.quality.value.text)
  opt.quality.down.scripts.OnClick(opt.quality.down)
  check("< lowers the quality limit to Rare", JunkAwayDB.settings.qualityLimit == 3 and opt.quality.value.text == "Rare")
  opt.quality.up.scripts.OnClick(opt.quality.up)
  check("warn-at shows Full", opt.warn.value.text == ns.L.OPTION_WARN_FULL, opt.warn.value.text)
  for _ = 1, 9 do opt.warn.up.scripts.OnClick(opt.warn.up) end
  check("warn-at stops at 5", JunkAwayDB.settings.warnAt == 5, JunkAwayDB.settings.warnAt)
  for _ = 1, 9 do opt.warn.down.scripts.OnClick(opt.warn.down) end
end
ok, out = slash("debug")
check("/ja debug runs", ok, out)
local report = JunkAwayDB.report and table.concat(JunkAwayDB.report, " | ") or ""
check("the report lists slots and the ranking", report:find("Linen Cloth", 1, true) and report:find("candidate 1", 1, true)
  and report:find("skip: special bag", 1, true) and report:find("unpriced", 1, true), report)

print(failed == 0 and "smoke test passed" or (failed .. " smoke check(s) failed"))
os.exit(failed == 0 and 0 or 1)
