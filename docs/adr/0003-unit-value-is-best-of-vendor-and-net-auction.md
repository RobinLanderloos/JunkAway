---
status: accepted
---

# Unit value is the better of vendor price and net auction price

A unit is worth what you could get for it: the higher of its vendor sell price and its auction price minus the 5% auction house cut. Soulbound items cannot be auctioned, so they only get their vendor price.

Auction prices come **only from Auctionator** (`Auctionator.API.v1.GetAuctionPriceByItemLink`/`ByItemID`), an optional dependency. Without Auctionator, vendor prices alone are used. Unlike DustOrGold (its ADR 0007/0008), JunkAway has no auction scanner of its own: that scanner is the most complex and laggiest part of DustOrGold, and the user runs Auctionator anyway. The age of an auction price is not taken into account in v1.

## Consequences

- Without Auctionator, a tradeable item with a high auction value but a low vendor price may be suggested.
- Adding an own scanner later means a new ADR and a new price source behind the same lookup function.
