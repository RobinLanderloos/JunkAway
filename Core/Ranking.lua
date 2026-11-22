-- Ranking: which bag slots to throw away first. A slot is worth what it
-- holds now (docs/adr/0001). Pure (docs/adr/0007): takes plain slot facts
-- and returns suggestions.
local _, ns = ...

local Ranking = {}
ns.Ranking = Ranking

Ranking.LIMIT = 3
Ranking.AUCTION_CUT_PERCENT = 5

-- What one unit is worth: the better of vendor price and auction price minus
-- the auction house cut; bound items can't be auctioned (docs/adr/0003).
-- nil when neither price is known.
function Ranking.UnitValue(fact, auctionPrice)
  local vendor = fact.vendorPrice
  if vendor and vendor <= 0 then vendor = nil end
  local net
  if auctionPrice and not fact.bound then
    local price = auctionPrice(fact.link, fact.itemID)
    if price and price > 0 then net = math.floor(price * (100 - Ranking.AUCTION_CUT_PERCENT) / 100) end
  end
  if vendor and net then return math.max(vendor, net) end
  return vendor or net
end

-- slots: { { bag, slot, itemID, link, count, maxStack, quality, classID,
--            vendorPrice, bound, family, locked } or { bag, slot, family, empty = true } }
-- opts:  { limit, auctionPrice = function(link, itemID) -> copper per unit or nil }
-- Returns { candidates = { slot fact + unitValue, value } }
function Ranking.Rank(slots, opts)
  local limit = opts.limit or Ranking.LIMIT
  local all, free = {}, 0
  for _, s in ipairs(slots) do
    if s.empty then
      free = free + 1
    else
      local unit = Ranking.UnitValue(s, opts.auctionPrice) or 0
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
