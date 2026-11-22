# CLAUDE.md

JunkAway is a WoW Forever addon (`## Interface: 16001`, retail-style API): when the bags are full it shows the cheapest slots to throw away. Auctionator is an optional dependency.

## Commands

```
luajit tests/run.lua          # unit tests for Core/ (exit 1 on failure)
luajit tests/smoke_test.lua   # loads every .toc file in order against a stub game API
pwsh scripts/package.ps1      # dist/JunkAway-<version>.zip + release.json
```

A new Core file goes in the `.toc` and in the load list at the top of `tests/run.lua`; a new test file in the list at the bottom of `tests/run.lua`.

## Architecture

- `Core/` is pure Lua, no WoW globals (ADR 0007). `Ranking.Rank(slots, opts)` is the heart: slot facts in, `{ candidates, merges, freeSlots, full }` out. `Settings` normalizes saved settings, `IgnoreList` the ignore set, `Display` row text.
- `Game/Adapter.lua` (`ns.Game`) reads bag slots into slot facts and prices from Auctionator. `Main.lua` holds saved variables and the watcher (open on not-full -> full). `Window`, `Options`, `Slash`, `Report` are UI.
- `Game/Skin.lua` is shared with the author's other addons; keep the copies identical.
- Saved variables: `JunkAwayDB` = { settings, ignore = { [itemID] = true }, window, report }.

## Design rules (docs/adr/)

- A slot is worth unit value x count, no potential-value bonus; stackable candidates are marked (0001).
- Merge before destroy; a merge only when both stacks fit in one (0002).
- Unit value = max(vendor, floor(auction x 95%)); bound = vendor only; Auctionator is the only auction source (0003).
- Never suggested: unpriced, quest (class 12), quality >= limit (default Epic), ignored, locked, not yet cached (0004).
- "Full" counts ordinary bags only (bag family 0) (0005).
- Never delete or sell: clicks pick items up (0006).
