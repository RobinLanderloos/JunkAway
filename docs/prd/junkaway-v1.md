# JunkAway v1

## Problem Statement

When my bags are full in WoW Forever I lose loot, quest items and rolls, and in the middle of a pull or a dungeon I have to scan five bags by eye to decide what to throw away. I can't easily tell which slot is the least valuable: a grey's vendor price, a stack of cloth's auction value and a green's worth are all on different tooltips, and some things (Hearthstone, quest items, a stack I'm building up) must never go.

## Solution

JunkAway watches the bags. The moment the ordinary bags become full, a small window opens with the three cheapest slots, cheapest first, each with its value. A slot's value is what it holds now: the better of the vendor price and the auction price (Auctionator, minus the 5% cut) times the count. Stackable items are marked so I notice I'm about to throw a stack away. If two partial stacks of the same item can be merged, that free fix is shown first with a Merge button. Clicking a row puts the item on my cursor; I drop it and the game asks for confirmation. Items I never want suggested can be ignored with one click and un-ignored from an Ignored list. Unpriced items, quest items and Epic-or-better items are never suggested.

## User Stories

1. As a player, I want a window to open the moment my bags become full, so that I can make room before the next loot.
2. As a player, I want the window to open only once per "became full" moment, so that it doesn't keep popping up while I sort things out.
3. As a player, I want the suggestion to disappear when a slot frees up, so that the window doesn't show stale advice.
4. As a player, I want to see the three cheapest slots, cheapest first, so that I have a choice if the first one is something I'd rather keep.
5. As a player, I want each row to show the item's icon, link and count, so that I recognise it at a glance.
6. As a player, I want each row to show the slot's value in gold/silver/copper, so that I see what I'd lose.
7. As a player, I want a slot's value to be what it holds now (unit value × count), so that the advice matches my actual loss.
8. As a player, I want a unit's value to be the higher of the vendor price and the net auction price, so that the value reflects the best I could get for it.
9. As a player, I want the auction price to have the 5% auction house cut taken off, so that it's comparable with the vendor price.
10. As a player with Auctionator, I want JunkAway to use Auctionator's prices, so that I don't need another scan.
11. As a player without Auctionator, I want JunkAway to still work on vendor prices, so that the addon is useful on its own.
12. As a player, I want soulbound items valued at their vendor price only, so that an auction price I can't realise doesn't protect them.
13. As a player, I want stackable items marked with their own colour, so that I notice I'm about to throw away a whole stack.
14. As a player, I want a merge suggestion when two partial stacks of the same item exist, so that I can free a slot without losing anything.
15. As a player, I want the merge shown above the destroy suggestions, so that the free option is the first thing I see.
16. As a player, I want a Merge button that moves one stack onto the other, so that I don't have to find both stacks.
17. As a player, I want to click a row to pick the item up onto my cursor, so that I only have to drop it to destroy it.
18. As a player, I want JunkAway never to delete anything itself, so that the final decision and the game's confirmation stay mine.
19. As a player, I want items with no price at all never suggested, so that my Hearthstone, keys and tools are safe.
20. As a player, I want quest items never suggested, so that I don't lose quest progress.
21. As a player, I want items at or above a quality limit (default Epic) never suggested, so that an unpriced epic is never at risk.
22. As a player, I want to set that quality limit, so that I can also protect Rare items if I want.
23. As a player, I want an Ignore button on each row, so that an item I want to keep disappears from the suggestions immediately.
24. As a player, I want ignoring to cover every stack of the same item, so that one click protects all my Silk Cloth.
25. As a player, I want the ignore list shared by all my characters, so that I set it up once.
26. As a player, I want an Ignored list in the window with a Remove button per item, so that I can undo an ignore and see why something never comes up.
27. As a player, I want `/ja unignore <item link>` to work too, so that I can un-ignore from chat.
28. As a player, I want `/ja ignore <item link>` too, so that I can ignore something before it ever comes up.
29. As a player, I want special bags (quiver, soul bag, herb bag) left out of "full", so that a free slot there doesn't count as room.
30. As a player, I want items in special bags never suggested, so that my arrows and shards are safe.
31. As a player, I want an optional "warn at N free slots" setting (default 0), so that I can be warned before a roll fails.
32. As a player, I want `/junkaway` or `/ja` to open the window any time, so that I can clear space before a dungeon even with free slots.
33. As a player, I want the window to show a clear message when there is nothing to suggest, so that I know it isn't broken.
34. As a player, I want the window to be movable and remember its position, so that it doesn't cover my action bars.
35. As a player, I want Escape to close the window, so that it behaves like other game windows.
36. As a player, I want the window in the same classic look as my other addons, so that my UI is consistent.
37. As a player, I want a settings page in the game's AddOns options, so that I can change the quality limit and warning threshold.
38. As a player, I want values to update when prices or bags change while the window is open, so that it doesn't show outdated rows.
39. As a player, I want the item tooltip when I hover a row, so that I can check what the item is.
40. As a developer, I want `/ja debug` to write the current slot facts and ranking to SavedVariables, so that I can read in-game state after a `/reload` (the user can't copy chat).
41. As a player, I want JunkAway to stay quiet in combat (no window popping up mid-fight) and open once combat ends if bags are still full, so that it doesn't get in the way.

## Implementation Decisions

Settled in `docs/adr/` (0001–0007); summary:

- **Ranking (Core, the deep module).** One function takes a list of plain slot facts, a price lookup and the settings/ignore list, and returns `{ full, freeSlots, merges, candidates, ignoredCount }`. It owns: unit value (max of vendor and auction × 0.95; bound → vendor only), slot value (unit × count), exclusions (unpriced, quest class, quality ≥ limit, ignored, special bag, locked), merge detection (same item ID, two or more slots below max stack, ordinary bags only), "full" (free ordinary slots ≤ warnAt), ordering (value ascending, then bag/slot for stability), top N.
  - Slot fact: `{ bag, slot, itemID, link, count, maxStack, quality, classID, vendorPrice, bound, family, locked }`; empty slots are `{ bag, slot, family, empty = true }`.
  - Candidate: the slot fact plus `unitValue`, `value`, `stackable`.
  - Merge: `{ itemID, link, from = slotFact, to = slotFact }` — moving the smaller stack onto the larger.
- **IgnoreList (Core).** Item ID parsing from a link/`item:` string/number; add/remove/contains/sorted list. Same shape as DustOrGold's KeepList.
- **Settings (Core).** Normalizes saved variables: `qualityLimit` (default 4 = Epic, clamped to 1–7), `warnAt` (default 0, 0–5), window position, ignore table. Unknown/old fields dropped, bad types reset.
- **Display (Core).** Plain text helpers: the merge row label ("Merge Linen Cloth (12 + 15)"), the empty-state text, the stack mark choice.
- **Game Adapter.** Reads every bag slot into slot facts (`C_Container.GetContainerNumSlots/GetContainerItemInfo/GetContainerNumFreeSlots` for the family, `C_Item.GetItemInfo` for max stack, quality, class, vendor price) and supplies `auctionPrice(link, itemID)` from Auctionator when present. Items not yet cached are skipped and a refresh is requested on `GET_ITEM_INFO_RECEIVED`.
- **Watcher.** On `BAG_UPDATE_DELAYED` (debounced), ranks; on the transition not-full → full opens the window (deferred until `PLAYER_REGEN_ENABLED` when in combat); when no longer full and the window was auto-opened, it closes.
- **Window.** Skinned window (`ns.Skin`), merge row on top, up to three candidate rows (icon, link, count, value, stack mark, Ignore button), a Suggestions/Ignored mode switch, Ignored list with Remove buttons. Row click: `C_Container.PickupContainerItem(bag, slot)`. Merge: pick up the source stack, then drop on the target slot.
- **Slash.** `/junkaway` and `/ja`: no args toggles the window; `ignore <link>`, `unignore <link>`, `debug`, `options`.
- **Options.** Canvas settings panel with quality limit and warn-at.
- **Skin.** Shared `Game/Skin.lua`, with a JunkAway accent added to `ACCENTS` in every copy.
- Saved variables: one account-wide table `JunkAwayDB` (settings, ignore list, window position, debug report).

## Testing Decisions

- Good tests drive the public interface with plain facts and assert on the returned suggestions/text; they don't look at internal helper functions.
- Unit tests (LuaJIT, `tests/run.lua`) for Ranking, IgnoreList, Settings and Display. Ranking tests use small invented bags: a grey vs a stack of cloth, a bound item with an auction price, an unpriced Hearthstone, a quest item, an epic, an ignored item, a special bag, two partial stacks, "full" with and without warnAt, ties.
- A smoke test (`tests/smoke_test.lua`) loads every `.toc` file against a stand-in for the game, fills bags so they're full, fires `BAG_UPDATE_DELAYED`, and checks the window opened with the right rows, Ignore works, the slash commands run.
- Prior art: DustOrGold `tests/run.lua`, `tests/smoke_test.lua`, `keeplist_test.lua`; the skill templates.

## Out of Scope

- Deleting items automatically or selling to vendors.
- An own auction scanner, price age.
- Potential value or bonuses for partial stacks.
- Bank and reagent bank.
- Per-character ignore lists.
- Tooltip lines on items in bags.
- Publishing (GitHub release, CurseForge): later, after in-game approval.

## Further Notes

- Unverified on Forever: picking up and merging bag items from an addon click; `GetContainerNumFreeSlots` returning the bag family. These are the first in-game checks.
- The `Enum.ItemQuality` scale: 0 Poor, 1 Common, 2 Uncommon, 3 Rare, 4 Epic, 5 Legendary. Quest items: `classID` 12.
