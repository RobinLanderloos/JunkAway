-- The ignore list: item IDs that are never suggested (docs/adr/0004).
local ns, test, eq = ...
local IL = ns.IgnoreList

test("item IDs are read from links, item strings and numbers", function()
  eq(IL.ItemID("|cffffffff|Hitem:4306::::::::10|h[Silk Cloth]|h|r"), 4306, "link")
  eq(IL.ItemID("item:4306"), 4306, "item string")
  eq(IL.ItemID(" 4306 "), 4306, "typed number")
  eq(IL.ItemID(4306), 4306, "number")
  eq(IL.ItemID("Silk Cloth"), nil, "a name")
end)

test("add, remove and list", function()
  local list = {}
  IL.Add(list, 4306); IL.Add(list, 2589)
  eq(IL.Contains(list, 4306), true)
  eq(table.concat(IL.List(list), ","), "2589,4306", "sorted")
  IL.Remove(list, 4306)
  eq(IL.Contains(list, 4306), false)
end)

test("ignored items are never suggested, whatever the stack", function()
  local slots = {
    { bag = 0, slot = 1, family = 0, itemID = 4306, count = 3, maxStack = 20, quality = 1, vendorPrice = 1 },
    { bag = 0, slot = 2, family = 0, itemID = 4306, count = 7, maxStack = 20, quality = 1, vendorPrice = 1 },
    { bag = 0, slot = 3, family = 0, itemID = 9, count = 1, maxStack = 1, quality = 1, vendorPrice = 50 },
  }
  local r = ns.Ranking.Rank(slots, { ignore = { [4306] = true } })
  eq(#r.candidates, 1)
  eq(r.candidates[1].itemID, 9)
end)
