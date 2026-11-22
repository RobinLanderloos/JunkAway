---
status: accepted
---

# Advice and pick-up, never deleting

JunkAway never destroys an item itself. Clicking a suggestion picks the item up onto the cursor; the user drops it outside the bags and the game's own confirmation (including "type DELETE" for rare items) does the rest. The merge suggestion likewise moves a stack only when its button is clicked. This follows DustOrGold's ADR 0005: the final decision stays with the player.

## Consequences

- Whether an addon may pick up and merge bag items from a click on Forever is unverified and is the first in-game check.
- Nothing happens in combat that could taint protected actions; pick-up is a plain click handler.
