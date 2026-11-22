# Settings panel and debug report

Type: AFK

## Parent

docs/prd/junkaway-v1.md

## State

Open

## What to build

A settings page in the AddOns options with the quality limit and warn-at threshold, and `/ja debug` writing slot facts and the ranking into saved variables for reading after /reload.

## Acceptance criteria

- [ ] Settings panel registered with the game's Settings UI; `/ja options` opens it
- [ ] Changing a setting re-ranks immediately
- [ ] `/ja debug` stores a report in JunkAwayDB
- [ ] Smoke test opens the panel and runs debug

## Blocked by

- docs/issues/003-never-suggested-rules.md
- docs/issues/005-auto-open-when-bags-become-full.md
