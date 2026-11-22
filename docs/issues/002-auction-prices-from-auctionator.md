# Auction prices from Auctionator

Type: AFK

## Parent

docs/prd/junkaway-v1.md

## State

Completed

## What to build

Unit value becomes the higher of vendor price and Auctionator's auction price minus 5%; soulbound items keep vendor price only. Without Auctionator, vendor price alone (ADR 0003).

## Acceptance criteria

- [x] Unit value = max(vendor, floor(auction x 0.95)) for unbound items
- [x] Bound items ignore the auction price
- [x] Adapter uses Auctionator's API only when it is loaded (OptionalDeps)
- [x] Tests cover: auction beats vendor, vendor beats auction, bound, no Auctionator

## Blocked by

- docs/issues/001-cheapest-slots-window-tracer-bullet.md
