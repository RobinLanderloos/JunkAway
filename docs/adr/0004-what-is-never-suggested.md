---
status: accepted
---

# What is never suggested

The rule "the cheapest slot goes" makes anything that scores 0 the first suggestion, which would mean destroying a Hearthstone, a key or a quest item. So these slots are never suggested:

- **Unpriced items**: neither a vendor price nor an auction price. "No price" means "unknown", not "worth 0".
- **Quest items** (item class Quest), even when they have a vendor price.
- **Items at or above a quality limit**, a setting with default Epic, as a guard against an unpriced or underpriced epic.
- **Ignored items**: a list of item IDs, account-wide (shared by all characters), with an Ignored list in the window to undo.

## Consequences

- A real junk item with no price at all never comes up; the user throws it away themselves.
- Ignoring is by item ID, so it covers every random-suffix version of an item.
