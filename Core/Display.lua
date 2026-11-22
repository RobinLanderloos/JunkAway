-- Text the window shows for suggestions. Pure (docs/adr/0007).
local _, ns = ...
local L = ns.L

local Display = {}
ns.Display = Display

function Display.MergeLabel(merge)
  local name = merge.name or ("item:" .. tostring(merge.itemID))
  return L.MERGE_LABEL:format(name, merge.from.count or 1, merge.to.count or 1)
end

-- The mark under a stackable candidate (docs/adr/0001): the whole stack goes.
function Display.StackNote(candidate)
  if not candidate.stackable then return "" end
  if (candidate.count or 1) > 1 then return L.WHOLE_STACK:format(candidate.count) end
  return L.STACKABLE
end
