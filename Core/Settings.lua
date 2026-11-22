-- Saved settings made safe to use: defaults for missing values, numbers
-- clamped to their range, unknown fields dropped. Pure (docs/adr/0007).
local _, ns = ...

local Settings = {}
ns.Settings = Settings

-- name = { default, lowest, highest }
Settings.FIELDS = {
  qualityLimit = { 4, 1, 7 }, -- never suggest this quality or better (4 = Epic)
  warnAt = { 0, 0, 5 },       -- bags count as full at this many free slots or fewer
}

function Settings.Normalize(saved)
  saved = type(saved) == "table" and saved or {}
  local out = {}
  for name, spec in pairs(Settings.FIELDS) do
    local v = tonumber(saved[name])
    if v then
      v = math.floor(v + 0.5)
      v = math.max(spec[2], math.min(spec[3], v))
    else
      v = spec[1]
    end
    out[name] = v
  end
  return out
end
