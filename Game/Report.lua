-- Diagnostic reports the developer can read without the player copying chat.
-- Everything said through ns.Report is printed AND stored in the saved
-- variables; after the player types /reload, read
--   F:\Games\World of Warcraft\_forever_\WTF\Account\<account>\SavedVariables\<Addon>.lua
-- (the user's account folder is 137380454#1).
local addonName, ns = ...

local Report = {}
ns.Report = Report

local lines

function Report.Start()
  local _, build, _, interface = GetBuildInfo()
  lines = { ("build %s, interface %s, %s"):format(tostring(build), tostring(interface),
    date and date("%Y-%m-%d %H:%M") or "") }
end

function Report.Say(text)
  print("|cff40ff40" .. addonName .. ":|r " .. text)
  if lines then lines[#lines + 1] = text end
end

-- db is the addon's SavedVariables table (set up in ADDON_LOADED).
function Report.Finish(db)
  db.report = lines
  lines = nil
end


-- /ja debug: every slot as JunkAway sees it, and the ranking.
function Report.Debug()
  Report.Start()
  local s = ns.settings
  Report.Say(("settings: qualityLimit %d, warnAt %d; Auctionator %s"):format(
    s.qualityLimit, s.warnAt, (Auctionator and Auctionator.API) and "yes" or "no"))
  local slots = ns.Game.ReadSlots()
  local opts = { auctionPrice = ns.Game.AuctionPrice, settings = s, ignore = ns.db.ignore }
  for _, f in ipairs(slots) do
    if not f.empty then
      local auction = ns.Game.AuctionPrice(f.link, f.itemID)
      local why = (f.family or 0) ~= 0 and "special bag" or ns.Ranking.Excluded(f, opts)
      local unit = ns.Ranking.UnitValue(f, opts.auctionPrice)
      if not why and not unit then why = "unpriced" end
      Report.Say(("%d:%d %s x%d q%s class %s stack %s vendor %s auction %s bound %s fam %d -> %s"):format(
        f.bag, f.slot, tostring(f.name or f.itemID), f.count or 1, tostring(f.quality), tostring(f.classID),
        tostring(f.maxStack), tostring(f.vendorPrice), tostring(auction), tostring(f.bound), f.family or 0,
        why and ("skip: " .. why) or ("unit " .. unit .. ", slot " .. unit * (f.count or 1))))
    end
  end
  local r = ns.Ranking.Rank(slots, opts)
  Report.Say(("free %d, full %s"):format(r.freeSlots, tostring(r.full)))
  for i, c in ipairs(r.candidates) do
    Report.Say(("candidate %d: %d:%d %s value %d"):format(i, c.bag, c.slot, tostring(c.name), c.value))
  end
  for _, m in ipairs(r.merges) do
    Report.Say(("merge: %s %d:%d (%d) onto %d:%d (%d)"):format(tostring(m.name), m.from.bag, m.from.slot,
      m.from.count, m.to.bag, m.to.slot, m.to.count))
  end
  Report.Finish(ns.db)
  Report.Say("report saved: /reload to write it to the SavedVariables file.")
end
