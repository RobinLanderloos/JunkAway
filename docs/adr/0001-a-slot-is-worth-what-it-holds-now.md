---
status: accepted
---

# A slot is worth what it holds now

When the bags are full the goal is one free slot, so JunkAway compares **slots**, not items: a suggestion always means "destroy the whole stack in this slot". A slot's value is `unit value × count` (unit value: ADR 0003), and the cheapest slot is suggested first.

We considered scoring partial stacks on what they could become (`unit value × max stack`, or a bonus multiplier), so that 4 Silk Cloth that keeps growing is not thrown away for a slightly dearer single item. We chose the plain current value: it matches what you actually lose now, is easy to check at a glance, and a made-up multiplier is hard to explain. A stack you are building up is protected by ignoring it (ADR 0004).

## Consequences

- A suggested slot that holds a stackable item (max stack > 1) is drawn with its own colour/mark, so the user notices they are about to throw away a stack.
- No "potential value" anywhere in the calculation.
