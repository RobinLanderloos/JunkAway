-- Ranking: which bag slots to throw away first. A slot is worth what it
-- holds now (docs/adr/0001). Pure (docs/adr/0007): takes plain slot facts
-- and returns suggestions.
local _, ns = ...

local Ranking = {}
ns.Ranking = Ranking

Ranking.LIMIT = 3

-- slots: { { bag, slot, itemID, link, count, maxStack, quality, classID,
--            vendorPrice, bound, family, locked } or { bag, slot, family, empty = true } }
-- opts:  { limit }
-- Returns { candidates = { slot fact + unitValue, value } }
function Ranking.Rank(slots, opts)
  local limit = opts.limit or Ranking.LIMIT
  local all, free = {}, 0
  for _, s in ipairs(slots) do
    if s.empty then
      free = free + 1
    else
      local unit = s.vendorPrice or 0
      local c = {}
      for k, v in pairs(s) do c[k] = v end
      c.unitValue = unit
      c.value = unit * (s.count or 1)
      all[#all + 1] = c
    end
  end
  table.sort(all, function(a, b)
    if a.value ~= b.value then return a.value < b.value end
    if a.bag ~= b.bag then return a.bag < b.bag end
    return a.slot < b.slot
  end)

  local candidates = {}
  for i = 1, math.min(limit, #all) do candidates[i] = all[i] end
  return { candidates = candidates, freeSlots = free }
end
