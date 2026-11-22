-- Display: the text the window shows.
local ns, test, eq = ...

test("merge label names the item and both stack sizes, smaller first", function()
  local m = { name = "Linen Cloth", from = { count = 5 }, to = { count = 12 } }
  eq(ns.Display.MergeLabel(m), "Merge Linen Cloth (5 + 12)")
end)

test("stack note says the whole stack goes", function()
  eq(ns.Display.StackNote({ stackable = true, count = 7 }), "Whole stack of 7")
  eq(ns.Display.StackNote({ stackable = true, count = 1 }), "Stackable")
  eq(ns.Display.StackNote({ stackable = false, count = 1 }), "")
end)
