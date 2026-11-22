---
status: accepted
---

# Merge before destroy

Two or more partial stacks of the same item (left behind by splits, trades or bank moves) can be merged to free a slot without losing anything. When such stacks exist, a "merge" suggestion is shown above the destroy suggestions.

## Consequences

- The merge suggestion is offered as an action (a button that moves one stack onto the other), not done automatically (ADR 0006).
- Items in special bags (ADR 0005) are not part of merge suggestions.
