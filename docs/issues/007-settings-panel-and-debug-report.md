# Settings panel and debug report

Type: AFK

## Parent

docs/prd/junkaway-v1.md

## State

Completed

## What to build

A settings page in the AddOns options with the quality limit and warn-at threshold, and `/ja debug` writing slot facts and the ranking into saved variables for reading after /reload.

## Acceptance criteria

- [x] Settings panel registered with the game's Settings UI; `/ja options` opens it
- [x] Changing a setting re-ranks immediately
- [x] `/ja debug` stores a report in JunkAwayDB
- [x] Smoke test opens the panel and runs debug

## Blocked by

- docs/issues/003-never-suggested-rules.md
- docs/issues/005-auto-open-when-bags-become-full.md
