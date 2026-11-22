---
status: accepted
---

# "Full" means the ordinary bags

Special bags (quiver, ammo pouch, soul bag, herb or enchanting bag) only take certain items, so a free slot there does not help to loot a sword. Bags count as full when the ordinary bags have no free slot (or at most the "warn at" threshold, a setting with default 0). Items in special bags are never candidates.

The addon checks on every bag change. When the bags become full, the window opens once; when a slot frees up, the suggestion disappears. A slash command (`/junkaway`, `/ja`) shows the suggestions at any time, full or not.

## Consequences

- Telling ordinary from special bags needs the bag's family (`C_Container.GetContainerNumFreeSlots` returns it as the second value; 0 = ordinary).
