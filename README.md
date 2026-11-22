# JunkAway

Made mainly for me and my friends. It's shared in case it's useful to others too, but expect it to follow our needs first.

A World of Warcraft addon for **WoW Forever** (interface 16001). When your bags are full, JunkAway opens a small window with the three cheapest slots in your bags, so you know what to throw away.

## What it does

- **Opens when your bags become full** and closes again when a slot frees up. In combat it waits until the fight is over. Special bags (quiver, soul bag, herb bag) don't count as room, and their items are never suggested.
- **Shows the cheapest slots first.** A slot is worth what's in it now: the higher of the vendor price and the auction price (from [Auctionator](https://www.curseforge.com/wow/addons/auctionator), minus the 5% auction cut), times the stack size. Soulbound items count at their vendor price only.
- **Marks stacks** in orange ("Whole stack of 7") so you notice when you'd throw away a whole stack.
- **Merge first:** when two partial stacks of the same item fit together, a green "Merge" row frees a slot for nothing.
- **Never deletes anything.** Click a row to pick the item up, then drop it outside your bags; the game asks for confirmation as usual.
- **Never suggests** items with no price at all (Hearthstone, keys), quest items, items of a chosen quality or better (default Epic), or items you ignore.
- **Ignore** an item with one click; it's kept out on all your characters. The Ignored list in the window undoes it.

## Commands

- `/ja` or `/junkaway`: show or hide the window
- `/ja ignore <item>`, `/ja unignore <item>`: shift-click an item or type its item ID
- `/ja options`: settings (quality limit, open the window at N free slots)
- `/ja debug`: writes what JunkAway sees into its saved variables (read after `/reload`)

## Development

```
luajit tests/run.lua          # unit tests for Core/
luajit tests/smoke_test.lua   # loads every .toc file against a stand-in for the game
pwsh scripts/package.ps1      # dist/JunkAway-<version>.zip and release.json
```

Design decisions are in `docs/adr/`, the plan in `docs/prd/`, work items in `docs/issues/`.

## License

MIT
