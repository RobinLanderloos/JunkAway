# Auto-open when bags become full

Type: AFK

## Parent

docs/prd/junkaway-v1.md

## State

Open

## What to build

Watch bag changes; when the ordinary bags go from not full to full (free ordinary slots <= warnAt, default 0) the window opens once; when they are no longer full an auto-opened window closes. Special bags don't count and their items are never candidates. In combat, opening waits for combat to end (ADR 0005).

## Acceptance criteria

- [ ] Special-bag slots (family ~= 0) excluded from free count and candidates
- [ ] Window opens on the not-full -> full transition only
- [ ] Auto-opened window closes when a slot frees up
- [ ] warnAt setting normalized (0-5)
- [ ] In combat the open is deferred to PLAYER_REGEN_ENABLED
- [ ] Tests for full/warnAt/special bags; smoke test fires BAG_UPDATE_DELAYED

## Blocked by

- docs/issues/001-cheapest-slots-window-tracer-bullet.md
