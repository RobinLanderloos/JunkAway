# Never-suggested rules

Type: AFK

## Parent

docs/prd/junkaway-v1.md

## State

Completed

## What to build

Slots without any price, quest items and items at or above the quality limit (setting, default Epic) are never suggested (ADR 0004). Locked slots are skipped too.

## Acceptance criteria

- [x] Unpriced items are excluded, not valued at 0
- [x] Quest class (12) excluded even with a vendor price
- [x] Quality >= limit excluded; limit stored in settings and normalized
- [x] Tests cover each rule

## Blocked by

- docs/issues/001-cheapest-slots-window-tracer-bullet.md
