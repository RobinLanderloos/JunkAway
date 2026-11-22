# Ignore list

Type: AFK

## Parent

docs/prd/junkaway-v1.md

## State

Completed

## What to build

Each row has an Ignore button; ignored item IDs (account-wide) never come up. The window has an Ignored mode listing them with Remove buttons. `/ja ignore <link>` and `/ja unignore <link>`.

## Acceptance criteria

- [x] Ignore button removes all stacks of that item ID from the suggestions immediately
- [x] Ignored mode lists ignored items by name with Remove
- [x] Slash ignore/unignore accept item links and IDs
- [x] Ignore list stored in the account-wide saved variables
- [x] Unit tests for IgnoreList and ranking exclusion; smoke test clicks Ignore

## Blocked by

- docs/issues/001-cheapest-slots-window-tracer-bullet.md
