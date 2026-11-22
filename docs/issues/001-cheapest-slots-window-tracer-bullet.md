# Cheapest slots window (tracer bullet)

Type: AFK

## Parent

docs/prd/junkaway-v1.md

## State

Completed

## What to build

Addon skeleton end to end: .toc, Locales, Core ranking on vendor prices, Game adapter reading the bags, skinned window listing the three cheapest slots (icon, link, count, value), `/junkaway` and `/ja` toggle it, clicking a row picks the item up. Unit tests and smoke test in place.

## Acceptance criteria

- [x] Ranking returns slots ordered by value (vendor price x count), cheapest first, top 3, stable on ties
- [x] Empty slots are counted as free and never candidates
- [x] `/ja` opens the window with the three cheapest slots; empty-state text when nothing qualifies
- [x] Row click calls the container pick-up for that bag/slot; hovering a row shows the item tooltip
- [x] Window is skinned, movable, remembers its position, closes with Escape
- [x] `luajit tests/run.lua` and `luajit tests/smoke_test.lua` pass

## Blocked by

None - can start immediately
