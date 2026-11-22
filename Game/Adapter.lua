-- The one place that reads the bags and prices for the pure core
-- (docs/adr/0007): turns every slot of the carried bags into a plain slot fact.
local addonName, ns = ...

local Game = {}
ns.Game = Game

-- Set when some item's details were not cached yet; GET_ITEM_INFO_RECEIVED
-- then asks for a refresh.
Game.waitingForItems = false

local function bagIDs()
  local last = NUM_BAG_SLOTS or 4
  local list = {}
  for bag = 0, last do list[#list + 1] = bag end
  return list
end

-- The bag's family: 0 for an ordinary bag, a bit mask for quivers, soul bags,
-- herb bags and the like (second return of GetContainerNumFreeSlots).
local function family(bag)
  if not (C_Container and C_Container.GetContainerNumFreeSlots) then return 0 end
  local _, fam = C_Container.GetContainerNumFreeSlots(bag)
  return tonumber(fam) or 0
end

function Game.ReadSlots()
  local slots = {}
  Game.waitingForItems = false
  for _, bag in ipairs(bagIDs()) do
    local size = C_Container.GetContainerNumSlots(bag) or 0
    local fam = size > 0 and family(bag) or 0
    for slot = 1, size do
      local info = C_Container.GetContainerItemInfo(bag, slot)
      if not info then
        slots[#slots + 1] = { bag = bag, slot = slot, family = fam, empty = true }
      else
        local link = info.hyperlink
        local s = {
          bag = bag, slot = slot, family = fam,
          itemID = info.itemID or tonumber(tostring(link):match("item:(%d+)")),
          link = link, icon = info.iconFileID,
          count = info.stackCount or 1,
          bound = info.isBound and true or false,
          locked = info.isLocked and true or false,
          quality = info.quality,
        }
        local name, _, quality, _, _, _, _, maxStack, _, _, sellPrice, classID = C_Item.GetItemInfo(link)
        if name then
          s.name = name
          s.quality = quality or s.quality
          s.maxStack = maxStack or 1
          s.vendorPrice = sellPrice
          s.classID = classID
        else
          s.unknown = true -- details not cached yet: never a candidate this time
          Game.waitingForItems = true
        end
        slots[#slots + 1] = s
      end
    end
  end
  return slots
end

-- The auction price of one unit from Auctionator, nil without it or without
-- a price (docs/adr/0003).
function Game.AuctionPrice(link, itemID)
  local api = Auctionator and Auctionator.API and Auctionator.API.v1
  if not api then return nil end
  local ok, price
  if link and api.GetAuctionPriceByItemLink then
    ok, price = pcall(api.GetAuctionPriceByItemLink, addonName, link)
  end
  if not (ok and price) and itemID and api.GetAuctionPriceByItemID then
    ok, price = pcall(api.GetAuctionPriceByItemID, addonName, itemID)
  end
  return ok and tonumber(price) or nil
end

-- Rank the bags as they are now.
function Game.Rank()
  return ns.Ranking.Rank(Game.ReadSlots(), {
    auctionPrice = Game.AuctionPrice,
    settings = ns.settings,
    ignore = ns.db and ns.db.ignore,
  })
end

-- An item's name and link by ID for the Ignored list; "item:<id>" until the
-- game has its details.
function Game.ItemName(itemID)
  local name, link = C_Item.GetItemInfo(itemID)
  if name then return name, link end
  if C_Item.RequestLoadItemDataByID then C_Item.RequestLoadItemDataByID(itemID) end
  Game.waitingForItems = true
  return "item:" .. itemID, nil
end

function Game.ItemIcon(itemID)
  if C_Item.GetItemIconByID then return C_Item.GetItemIconByID(itemID) end
  return select(10, C_Item.GetItemInfo(itemID))
end

function Game.Money(copper)
  if C_CurrencyInfo and C_CurrencyInfo.GetCoinTextureString then
    return C_CurrencyInfo.GetCoinTextureString(copper)
  end
  return tostring(copper) .. "c"
end
