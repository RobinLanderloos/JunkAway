-- The ignore list: item IDs that are never suggested, shared by all
-- characters (docs/adr/0004). Pure (docs/adr/0007).
local _, ns = ...

local IgnoreList = {}
ns.IgnoreList = IgnoreList

-- The item ID in an item link, an "item:123" string or a bare number.
function IgnoreList.ItemID(text)
  if type(text) == "number" then return text end
  if type(text) ~= "string" then return nil end
  return tonumber(text:match("item:(%d+)") or text:match("^%s*(%d+)%s*$"))
end

function IgnoreList.Add(list, itemID) list[itemID] = true end
function IgnoreList.Remove(list, itemID) list[itemID] = nil end
function IgnoreList.Contains(list, itemID) return list ~= nil and list[itemID] == true end

function IgnoreList.List(list)
  local ids = {}
  for itemID in pairs(list) do ids[#ids + 1] = itemID end
  table.sort(ids)
  return ids
end
