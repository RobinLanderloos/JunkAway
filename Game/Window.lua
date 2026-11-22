-- The suggestions window: the cheapest slots, cheapest first. Clicking a row
-- picks the item up; JunkAway never deletes anything (docs/adr/0006).
local addonName, ns = ...
local L = ns.L

local Window = {}
ns.Window = Window

local WIDTH, ROW_H, PAD = 360, 36, 12
local frame, info, hint, empty
local rows = {}

local function showTooltip(row)
  if not row.fact then return end
  GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
  if GameTooltip.SetBagItem then
    GameTooltip:SetBagItem(row.fact.bag, row.fact.slot)
  elseif row.fact.link then
    GameTooltip:SetHyperlink(row.fact.link)
  end
  GameTooltip:Show()
end

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

  local value = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  value:SetPoint("RIGHT", -8, 0)
  value:SetJustifyH("RIGHT")
  row.value = value

  local name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  name:SetPoint("LEFT", icon, "RIGHT", 8, 0)
  name:SetPoint("RIGHT", value, "LEFT", -8, 0)
  name:SetJustifyH("LEFT")
  name:SetWordWrap(false)
  row.label = name

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
  row:Show()
end

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
  frame:SetScript("OnHide", function() Window.autoOpened = false end)

  info = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  info:SetPoint("TOPLEFT", PAD, -24)
  info:SetJustifyH("LEFT")

  for i = 1, ns.Ranking.LIMIT do
    local row = makeRow(i)
    row:SetPoint("TOPLEFT", PAD, -40 - (i - 1) * ROW_H)
    row:SetPoint("RIGHT", frame, "RIGHT", -PAD, 0)
    rows[i] = row
  end

  empty = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  empty:SetPoint("TOPLEFT", PAD, -48)
  empty:SetPoint("RIGHT", frame, "RIGHT", -PAD, 0)
  empty:SetJustifyH("LEFT")
  empty:SetText(L.NOTHING)

  hint = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  hint:SetPoint("BOTTOMLEFT", PAD, 12)
  hint:SetPoint("RIGHT", frame, "RIGHT", -PAD, 0)
  hint:SetJustifyH("LEFT")
  hint:SetText(L.PICK_UP_HINT)

  frame:SetSize(WIDTH, 40 + ns.Ranking.LIMIT * ROW_H + 36)
end

function Window.Refresh()
  if not frame or not frame:IsShown() then return end
  local r = ns.Game.Rank()
  Window.last = r
  info:SetText(L.FREE_SLOTS:format(r.freeSlots or 0))
  for i, row in ipairs(rows) do
    local c = r.candidates[i]
    if c then fillRow(row, c) else row.fact = nil; row:Hide() end
  end
  empty:SetShown(#r.candidates == 0)
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
