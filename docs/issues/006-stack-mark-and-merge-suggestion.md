# Stack mark and merge suggestion

Type: AFK

## Parent

docs/prd/junkaway-v1.md

## State

Completed

## What to build

Stackable candidates get their own colour/mark (ADR 0001). When two partial stacks of the same item exist in ordinary bags, a merge row appears above the candidates with a Merge button that moves the smaller stack onto the larger (ADR 0002).

## Acceptance criteria

- [x] Candidates carry `stackable` (max stack > 1) and the row shows the stack mark
- [x] Merge detection: same item ID, both below max stack, ordinary bags, not locked; smaller onto larger
- [x] Merge row label 'Merge <name> (a + b)' and a Merge button doing pick-up + drop
- [x] Tests for merge detection and label

## Blocked by

- docs/issues/001-cheapest-slots-window-tracer-bullet.md
