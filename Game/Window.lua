-- The suggestions window: the cheapest slots, cheapest first, and the
-- Ignored list. Clicking a row picks the item up; JunkAway never deletes
-- anything (docs/adr/0006).
local addonName, ns = ...
local L = ns.L

local Window = {}
ns.Window = Window

local WIDTH, ROW_H, PAD, TOP = 380, 36, 12, 48
local IGNORED_ROWS, IGNORED_H = 6, 24
local CONTENT_H = (ns.Ranking.LIMIT + 1) * ROW_H -- room for the merge row too
local frame, info, hint, empty, modeButton
local rows, ignoredRows = {}, {}
local mode = "suggest" -- or "ignored"
local ignoredOffset = 0

local function showTooltip(row)
  local f = row.fact
  if not f then return end
  GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
  if f.bag and GameTooltip.SetBagItem then
    GameTooltip:SetBagItem(f.bag, f.slot)
  elseif f.link then
    GameTooltip:SetHyperlink(f.link)
  elseif f.itemID then
    GameTooltip:SetHyperlink("item:" .. f.itemID)
  end
  GameTooltip:Show()
end

local function smallButton(parent, text, width)
  local b = ns.Skin.Button(CreateFrame("Button", nil, parent))
  b:SetSize(width or 64, 22)
  b:SetText(text)
  return b
end

-- ------------------------------------------------------------- suggestions
local function makeRow(index)
  local row = CreateFrame("Button", nil, frame)
  row:SetHeight(ROW_H)
  ns.Skin.Row(row, index)
  row:RegisterForClicks("LeftButtonUp")

  local icon = row:CreateTexture(nil, "ARTWORK")
  icon:SetSize(28, 28)
  icon:SetPoint("LEFT", 4, 0)
  row.icon = icon

  local count = row:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
  count:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", -1, 1)
  row.count = count

  local ignore = smallButton(row, L.IGNORE)
  ignore:SetPoint("RIGHT", -4, 0)
  ignore:SetScript("OnClick", function()
    if row.fact and row.fact.itemID then Window.Ignore(row.fact.itemID) end
  end)
  row.ignore = ignore

  local value = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  value:SetPoint("RIGHT", ignore, "LEFT", -8, 0)
  value:SetJustifyH("RIGHT")
  row.value = value

  local name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  name:SetPoint("TOPLEFT", icon, "TOPRIGHT", 8, -1)
  name:SetPoint("RIGHT", value, "LEFT", -8, 0)
  name:SetJustifyH("LEFT")
  name:SetWordWrap(false)
  row.label = name

  local note = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  note:SetPoint("BOTTOMLEFT", icon, "BOTTOMRIGHT", 8, 1)
  note:SetJustifyH("LEFT")
  row.note = note

  row:SetScript("OnClick", function(self)
    local f = self.fact
    if f and C_Container and C_Container.PickupContainerItem then
      C_Container.PickupContainerItem(f.bag, f.slot)
    end
  end)
  row:SetScript("OnEnter", showTooltip)
  row:SetScript("OnLeave", function() GameTooltip:Hide() end)
  return row
end

local function fillRow(row, fact)
  row.fact = fact
  row.icon:SetTexture(fact.icon)
  row.count:SetText((fact.count or 1) > 1 and tostring(fact.count) or "")
  row.label:SetText(fact.link or fact.name or ("item:" .. tostring(fact.itemID)))
  row.value:SetText(ns.Game.Money(fact.value))
  row.note:SetText("")
  row:Show()
end

-- ------------------------------------------------------------- ignored list
local function makeIgnoredRow(index)
  local row = CreateFrame("Button", nil, frame)
  row:SetHeight(IGNORED_H)
  ns.Skin.Row(row, index)

  local icon = row:CreateTexture(nil, "ARTWORK")
  icon:SetSize(20, 20)
  icon:SetPoint("LEFT", 4, 0)
  row.icon = icon

  local remove = smallButton(row, L.REMOVE, 70)
  remove:SetHeight(20)
  remove:SetPoint("RIGHT", -4, 0)
  remove:SetScript("OnClick", function()
    if row.fact then Window.Unignore(row.fact.itemID) end
  end)
  row.remove = remove

  local name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  name:SetPoint("LEFT", icon, "RIGHT", 8, 0)
  name:SetPoint("RIGHT", remove, "LEFT", -8, 0)
  name:SetJustifyH("LEFT")
  name:SetWordWrap(false)
  row.label = name

  row:SetScript("OnEnter", showTooltip)
  row:SetScript("OnLeave", function() GameTooltip:Hide() end)
  return row
end

local function refreshIgnored()
  local ids = ns.IgnoreList.List(ns.db.ignore)
  local maxOffset = math.max(0, #ids - IGNORED_ROWS)
  ignoredOffset = math.max(0, math.min(ignoredOffset, maxOffset))
  for i, row in ipairs(ignoredRows) do
    local id = ids[i + ignoredOffset]
    if id then
      local name, link = ns.Game.ItemName(id)
      row.fact = { itemID = id, link = link }
      row.label:SetText(link or name)
      row.icon:SetTexture(ns.Game.ItemIcon(id))
      row:Show()
    else
      row.fact = nil
      row:Hide()
    end
  end
  info:SetText(L.IGNORED_COUNT:format(#ids))
  empty:SetText(L.NOTHING_IGNORED)
  empty:SetShown(#ids == 0)
  hint:SetText(#ids > IGNORED_ROWS and L.SCROLL_HINT or L.IGNORE_HINT)
end

-- ------------------------------------------------------------------- build
local function savePosition()
  local point, _, relPoint, x, y = frame:GetPoint()
  ns.db.window = { point = point, relPoint = relPoint, x = x, y = y }
end

local function build()
  frame = ns.Skin.Window(CreateFrame("Frame", "JunkAwayWindow", UIParent))
  frame.TitleText:SetText(L.TITLE)
  frame:SetFrameStrata("HIGH")
  frame:SetToplevel(true)
  frame:SetClampedToScreen(true)
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", frame.StartMoving)
  frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    savePosition()
  end)
  local pos = type(ns.db.window) == "table" and ns.db.window or {}
  if pos.point then
    frame:SetPoint(pos.point, UIParent, pos.relPoint or pos.point, tonumber(pos.x) or 0, tonumber(pos.y) or 0)
  else
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 120)
  end
  frame:Hide()
  tinsert(UISpecialFrames, "JunkAwayWindow") -- Escape closes it
  frame:SetScript("OnShow", function() Window.Refresh() end)
  frame:SetScript("OnHide", function()
    Window.autoOpened = false
    mode = "suggest"
  end)
  frame:EnableMouseWheel(true)
  frame:SetScript("OnMouseWheel", function(_, delta)
    if mode ~= "ignored" then return end
    ignoredOffset = ignoredOffset - delta
    refreshIgnored()
  end)

  info = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  info:SetPoint("TOPLEFT", PAD, -26)
  info:SetJustifyH("LEFT")

  modeButton = smallButton(frame, L.IGNORED, 96)
  modeButton:SetPoint("TOPRIGHT", -PAD, -20)
  modeButton:SetScript("OnClick", function()
    mode = mode == "ignored" and "suggest" or "ignored"
    ignoredOffset = 0
    Window.Refresh()
  end)

  for i = 1, ns.Ranking.LIMIT + 1 do
    local row = makeRow(i)
    row:SetPoint("TOPLEFT", PAD, -TOP - (i - 1) * ROW_H)
    row:SetPoint("RIGHT", frame, "RIGHT", -PAD, 0)
    row:Hide()
    rows[i] = row
  end
  for i = 1, IGNORED_ROWS do
    local row = makeIgnoredRow(i)
    row:SetPoint("TOPLEFT", PAD, -TOP - (i - 1) * IGNORED_H)
    row:SetPoint("RIGHT", frame, "RIGHT", -PAD, 0)
    row:Hide()
    ignoredRows[i] = row
  end

  empty = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  empty:SetPoint("TOPLEFT", PAD, -TOP - 8)
  empty:SetPoint("RIGHT", frame, "RIGHT", -PAD, 0)
  empty:SetJustifyH("LEFT")

  hint = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  hint:SetPoint("BOTTOMLEFT", PAD, 12)
  hint:SetPoint("RIGHT", frame, "RIGHT", -PAD, 0)
  hint:SetJustifyH("LEFT")

  frame:SetSize(WIDTH, TOP + CONTENT_H + 34)
end

local function refreshSuggestions()
  local r = ns.Game.Rank()
  Window.last = r
  info:SetText(L.FREE_SLOTS:format(r.freeSlots or 0))
  for i, row in ipairs(rows) do
    local c = r.candidates[i]
    if c then fillRow(row, c) else row.fact = nil; row:Hide() end
  end
  empty:SetText(L.NOTHING)
  empty:SetShown(#r.candidates == 0)
  hint:SetText(L.PICK_UP_HINT)
end

function Window.Refresh()
  if not frame or not frame:IsShown() then return end
  local ignored = mode == "ignored"
  modeButton:SetText(ignored and L.BACK or L.IGNORED)
  for _, row in ipairs(rows) do if ignored then row.fact = nil; row:Hide() end end
  for _, row in ipairs(ignoredRows) do if not ignored then row.fact = nil; row:Hide() end end
  if ignored then refreshIgnored() else refreshSuggestions() end
end

function Window.Ignore(itemID)
  ns.IgnoreList.Add(ns.db.ignore, itemID)
  Window.Refresh()
end

function Window.Unignore(itemID)
  ns.IgnoreList.Remove(ns.db.ignore, itemID)
  Window.Refresh()
end

function Window.Show(auto)
  if not frame then build() end
  if not frame:IsShown() then
    frame:Show()
    Window.autoOpened = auto and true or false
  else
    Window.Refresh()
  end
end

function Window.Hide()
  if frame then frame:Hide() end
end

function Window.Toggle()
  if frame and frame:IsShown() then Window.Hide() else Window.Show(false) end
end

function Window.IsShown()
  return frame ~= nil and frame:IsShown()
end
