-- Ranking: which slots to throw away first (docs/adr/0001-0005).
local ns, test, eq = ...
local Rank = function(slots, opts) return ns.Ranking.Rank(slots, opts or {}) end

-- A slot fact as the game adapter builds it; defaults for a plain item.
local nextSlot = 0
local function item(fields)
  nextSlot = nextSlot + 1
  local s = { bag = 0, slot = nextSlot, family = 0, count = 1, maxStack = 1, quality = 1, classID = 15, vendorPrice = 0 }
  for k, v in pairs(fields) do s[k] = v end
  return s
end
local function empty(fields)
  nextSlot = nextSlot + 1
  local s = { bag = 0, slot = nextSlot, family = 0, empty = true }
  for k, v in pairs(fields or {}) do s[k] = v end
  return s
end
local function ids(list)
  local out = {}
  for i, c in ipairs(list) do out[i] = tostring(c.itemID) end
  return table.concat(out, ",")
end

test("cheapest slots first, by vendor price times count", function()
  local r = Rank({
    item({ itemID = 1, vendorPrice = 100 }),             -- 100
    item({ itemID = 2, vendorPrice = 10, count = 5 }),   -- 50
    item({ itemID = 3, vendorPrice = 300 }),             -- 300
    item({ itemID = 4, vendorPrice = 20, count = 4 }),   -- 80
  })
  eq(ids(r.candidates), "2,4,1")
  eq(r.candidates[1].value, 50, "slot value")
  eq(r.candidates[1].unitValue, 10, "unit value")
end)

test("empty slots count as free and are never candidates", function()
  local r = Rank({ empty(), item({ itemID = 1, vendorPrice = 5 }), empty() })
  eq(ids(r.candidates), "1")
  eq(r.freeSlots, 2, "free slots")
end)

test("equal values keep bag and slot order", function()
  local r = Rank({
    item({ itemID = 3, bag = 2, slot = 1, vendorPrice = 7 }),
    item({ itemID = 2, bag = 0, slot = 9, vendorPrice = 7 }),
    item({ itemID = 1, bag = 0, slot = 4, vendorPrice = 7 }),
  })
  eq(ids(r.candidates), "1,2,3")
end)

-- ---------------------------------------------------------------- 002 auction prices
local function auction(prices) return function(_, itemID) return prices[itemID] end end

test("auction price minus the 5% cut beats a lower vendor price", function()
  local r = Rank({
    item({ itemID = 1, vendorPrice = 50 }),
    item({ itemID = 2, vendorPrice = 10 }),   -- auction 100 -> 95
  }, { auctionPrice = auction({ [2] = 100 }) })
  eq(ids(r.candidates), "1,2")
  eq(r.candidates[2].unitValue, 95, "net auction")
end)

test("vendor price wins when it is higher than the net auction price", function()
  local r = Rank({ item({ itemID = 1, vendorPrice = 60 }) }, { auctionPrice = auction({ [1] = 50 }) })
  eq(r.candidates[1].unitValue, 60)
end)

test("the cut is rounded down to whole copper", function()
  local r = Rank({ item({ itemID = 1, vendorPrice = 1 }) }, { auctionPrice = auction({ [1] = 33 }) })
  eq(r.candidates[1].unitValue, 31) -- 31.35
end)

test("soulbound items ignore the auction price", function()
  local r = Rank({ item({ itemID = 1, vendorPrice = 5, bound = true }) }, { auctionPrice = auction({ [1] = 1000 }) })
  eq(r.candidates[1].unitValue, 5)
end)

-- ---------------------------------------------------------------- 003 never suggested
test("an item with no price at all is never suggested (Hearthstone)", function()
  local r = Rank({ item({ itemID = 6948, vendorPrice = 0, bound = true }), item({ itemID = 2, vendorPrice = 40 }) })
  eq(ids(r.candidates), "2")
end)

test("quest items are never suggested, even with a vendor price", function()
  local r = Rank({ item({ itemID = 1, classID = 12, vendorPrice = 1 }), item({ itemID = 2, vendorPrice = 40 }) })
  eq(ids(r.candidates), "2")
end)

test("items at or above the quality limit are never suggested (default Epic)", function()
  local slots = {
    item({ itemID = 1, quality = 4, vendorPrice = 1 }),
    item({ itemID = 2, quality = 3, vendorPrice = 2 }),
    item({ itemID = 3, quality = 0, vendorPrice = 3 }),
  }
  eq(ids(Rank(slots).candidates), "2,3", "default")
  eq(ids(Rank(slots, { settings = { qualityLimit = 3 } }).candidates), "3", "limit Rare")
end)

test("locked slots and items whose details aren't loaded are skipped", function()
  local r = Rank({
    item({ itemID = 1, vendorPrice = 1, locked = true }),
    item({ itemID = 2, unknown = true }),
    item({ itemID = 3, vendorPrice = 9 }),
  })
  eq(ids(r.candidates), "3")
  eq(r.freeSlots, 0, "they still fill their slot")
end)

-- ---------------------------------------------------------------- 005 full
test("bags are full when no ordinary slot is free", function()
  eq(Rank({ item({ itemID = 1, vendorPrice = 1 }) }).full, true, "full")
  eq(Rank({ item({ itemID = 1, vendorPrice = 1 }), empty() }).full, false, "one free")
end)

test("warnAt counts a few free slots as full", function()
  local slots = { item({ itemID = 1, vendorPrice = 1 }), empty(), empty() }
  eq(Rank(slots, { settings = { warnAt = 2 } }).full, true, "2 free, warn at 2")
  eq(Rank(slots, { settings = { warnAt = 1 } }).full, false, "2 free, warn at 1")
end)

test("special bags neither count as room nor give candidates", function()
  local r = Rank({
    item({ itemID = 1, vendorPrice = 50 }),
    item({ itemID = 2512, vendorPrice = 1, count = 200, maxStack = 200, family = 1, bag = 1 }), -- arrows in a quiver
    empty({ family = 1, bag = 1 }),
  })
  eq(ids(r.candidates), "1")
  eq(r.freeSlots, 0, "quiver slot isn't room")
  eq(r.full, true)
end)
