-- Settings: saved values made safe to use.
local ns, test, eq = ...

test("missing settings get their defaults", function()
  local s = ns.Settings.Normalize(nil)
  eq(s.qualityLimit, 4, "quality limit Epic")
  eq(s.warnAt, 0, "warn at")
end)

test("out-of-range and wrong-type values are reset or clamped", function()
  local s = ns.Settings.Normalize({ qualityLimit = 9, warnAt = "lots", stray = true })
  eq(s.qualityLimit, 7, "clamped")
  eq(s.warnAt, 0, "reset")
  eq(s.stray, nil, "unknown field dropped")
  eq(ns.Settings.Normalize({ qualityLimit = 0, warnAt = 9 }).qualityLimit, 1, "low clamp")
  eq(ns.Settings.Normalize({ warnAt = 9 }).warnAt, 5, "warn clamp")
  eq(ns.Settings.Normalize({ qualityLimit = 2.6 }).qualityLimit, 3, "rounded")
end)
