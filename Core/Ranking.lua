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
-- opts:  { limit, settings = { qualityLimit, warnAt }, ignore = { [itemID] = true },
--          auctionPrice = function(link, itemID) -> copper per unit or nil }
-- Returns { candidates = { slot fact + unitValue, value, stackable },
--           merges = { { itemID, link, name, from = slot fact, to = slot fact } },
--           freeSlots, full }
Ranking.QUEST_CLASS = 12
Ranking.DEFAULT_QUALITY_LIMIT = 4 -- Epic

-- Why a filled slot is never suggested (docs/adr/0004), or nil.
function Ranking.Excluded(fact, opts)
  local settings = opts and opts.settings or {}
  if fact.unknown then return "unknown" end
  if fact.locked then return "locked" end
  if opts and opts.ignore and opts.ignore[fact.itemID] then return "ignored" end
  if fact.classID == Ranking.QUEST_CLASS then return "quest" end
  local limit = settings.qualityLimit or Ranking.DEFAULT_QUALITY_LIMIT
  if (fact.quality or 0) >= limit then return "quality" end
  return nil
end

-- Can this slot take part in a merge? Ordinary bag, loaded, not locked,
-- a stackable item below its max stack.
local function partial(s)
  return (s.family or 0) == 0 and not s.empty and not s.unknown and not s.locked
    and (s.maxStack or 1) > 1 and (s.count or 1) < s.maxStack
end

local function bySlot(a, b)
  if a.bag ~= b.bag then return a.bag < b.bag end
  return a.slot < b.slot
end

-- Partial stacks of one item that fit together free a slot for nothing
-- (docs/adr/0002): the smallest stack onto the largest one it still fits on.
-- Ignored items merge too, since nothing is lost. One merge per item.
local function findMerges(slots)
  local groups, order = {}, {}
  for _, s in ipairs(slots) do
    if partial(s) then
      if not groups[s.itemID] then groups[s.itemID] = {}; order[#order + 1] = s.itemID end
      table.insert(groups[s.itemID], s)
    end
  end
  table.sort(order)
  local merges = {}
  for _, itemID in ipairs(order) do
    local g = groups[itemID]
    if #g >= 2 then
      table.sort(g, function(a, b)
        if a.count ~= b.count then return a.count < b.count end
        return bySlot(a, b)
      end)
      local from, to = g[1], nil
      for i = #g, 2, -1 do
        if g[i].count + from.count <= from.maxStack then to = g[i]; break end
      end
      if to then
        merges[#merges + 1] = { itemID = itemID, link = from.link, name = from.name, from = from, to = to }
      end
    end
  end
  return merges
end

function Ranking.Rank(slots, opts)
  local limit = opts.limit or Ranking.LIMIT
  local settings = opts.settings or {}
  local all, free = {}, 0
  for _, s in ipairs(slots) do
    if (s.family or 0) ~= 0 then
      -- special bag (quiver, soul bag, herb bag): not room, not a candidate (docs/adr/0005)
    elseif s.empty then
      free = free + 1
    elseif not Ranking.Excluded(s, opts) then
      local unit = Ranking.UnitValue(s, opts.auctionPrice)
      if unit then
        local c = {}
        for k, v in pairs(s) do c[k] = v end
        c.unitValue = unit
        c.value = unit * (s.count or 1)
        c.stackable = (s.maxStack or 1) > 1
        all[#all + 1] = c
      end
    end
  end
  table.sort(all, function(a, b)
    if a.value ~= b.value then return a.value < b.value end
    return bySlot(a, b)
  end)

  local candidates = {}
  for i = 1, math.min(limit, #all) do candidates[i] = all[i] end
  return {
    candidates = candidates,
    merges = findMerges(slots),
    freeSlots = free,
    full = free <= (settings.warnAt or 0),
  }
end
