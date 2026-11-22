# Ignore list

Type: AFK

## Parent

docs/prd/junkaway-v1.md

## State

Open

## What to build

Each row has an Ignore button; ignored item IDs (account-wide) never come up. The window has an Ignored mode listing them with Remove buttons. `/ja ignore <link>` and `/ja unignore <link>`.

## Acceptance criteria

- [ ] Ignore button removes all stacks of that item ID from the suggestions immediately
- [ ] Ignored mode lists ignored items by name with Remove
- [ ] Slash ignore/unignore accept item links and IDs
- [ ] Ignore list stored in the account-wide saved variables
- [ ] Unit tests for IgnoreList and ranking exclusion; smoke test clicks Ignore

## Blocked by

- docs/issues/001-cheapest-slots-window-tracer-bullet.md
