-- The settings panel (Options > AddOns > JunkAway), also /ja options.
local addonName, ns = ...

local L = ns.L
local category

local function help(widget, title, text)
  widget:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(title)
    GameTooltip:AddLine(text, 1, 1, 1, true)
    GameTooltip:Show()
  end)
  widget:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

local function qualityName(q)
  local name = _G["ITEM_QUALITY" .. q .. "_DESC"] or tostring(q)
  local color = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[q]
  if color and color.hex then return color.hex .. name .. "|r" end
  return name
end

-- A label, a value and "<" ">" buttons that step one setting through its range.
local function stepper(panel, anchor, field, title, helpText, show)
  local spec = ns.Settings.FIELDS[field]
  local label = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  label:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -18)
  label:SetWidth(220)
  label:SetJustifyH("LEFT")
  label:SetText(title)

  local down = ns.Skin.Button(ns.Skin.Create("Button", nil, panel, ns.Skin.TEMPLATES.Button))
  down:SetSize(26, 22)
  down:SetPoint("LEFT", label, "RIGHT", 8, 0)
  down:SetText("<")
  local value = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  value:SetPoint("LEFT", down, "RIGHT", 8, 0)
  value:SetWidth(90)
  local up = ns.Skin.Button(ns.Skin.Create("Button", nil, panel, ns.Skin.TEMPLATES.Button))
  up:SetSize(26, 22)
  up:SetPoint("LEFT", value, "RIGHT", 8, 0)
  up:SetText(">")

  local control = { label = label, value = value, up = up, down = down }
  function control.Update()
    value:SetText(show(ns.settings[field]))
  end
  local function step(delta)
    local v = math.max(spec[2], math.min(spec[3], ns.settings[field] + delta))
    ns.settings[field] = v
    control.Update()
    ns.Main.Update()
  end
  down:SetScript("OnClick", function() step(-1) end)
  up:SetScript("OnClick", function() step(1) end)
  help(down, title, helpText)
  help(up, title, helpText)
  return control
end

local function build()
  local panel = CreateFrame("Frame")
  panel:Hide() -- so OnShow fires the first time the settings show it
  panel.name = addonName

  local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalHuge")
  title:SetPoint("TOPLEFT", 16, -16)
  title:SetText(addonName)
  title:SetTextColor(unpack(ns.Skin.accent))
  local sub = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
  sub:SetText(L.SLASH_HELP)

  local quality = stepper(panel, sub, "qualityLimit", L.OPTION_QUALITY, L.OPTION_QUALITY_HELP, qualityName)
  local warn = stepper(panel, quality.label, "warnAt", L.OPTION_WARN, L.OPTION_WARN_HELP, function(v)
    return v == 0 and L.OPTION_WARN_FULL or L.OPTION_WARN_FREE:format(v)
  end)

  local note = panel:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
  note:SetPoint("TOPLEFT", warn.label, "BOTTOMLEFT", 0, -24)
  note:SetWidth(520)
  note:SetJustifyH("LEFT")
  note:SetText(L.OPTION_NOTE)

  panel:SetScript("OnShow", function()
    quality.Update()
    warn.Update()
  end)
  ns.Options = { panel = panel, quality = quality, warn = warn }

  category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
  Settings.RegisterAddOnCategory(category)
end

function ns.OpenOptions()
  if category then Settings.OpenToCategory(category:GetID()) end
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function()
  local ok, err = pcall(build)
  if not ok then ns.Say("the settings panel could not be built: " .. tostring(err)) end
end)
