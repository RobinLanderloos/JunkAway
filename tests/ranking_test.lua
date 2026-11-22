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
