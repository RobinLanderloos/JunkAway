---
status: accepted
---

# Pure core, tested outside the game

As in DustOrGold (its ADR 0006): the ranking (slot values, exclusions, merge pairs, "is full") lives in `Core/` files that make no game calls. They take plain slot facts (bag, slot, item ID, count, max stack, quality, class, vendor price, bound or not, bag family) and a price lookup function, and return the suggestions. `Game/` reads those facts from the client and draws the window. The core is tested with LuaJIT from the command line; a smoke test loads every `.toc` file against a stand-in for the game.

## Consequences

- `Core/` stays free of WoW globals.
- Passing tests outside the game do not prove the client behaves like the stand-in; in-game checks are reported separately.
