# Sora Tsunagi — Build Plan v1 (first playable)
Status: IN PROGRESS, 2026-11-08. The phone test is on PR #4 and is not merged.

This build starts in **Moonheld** (guardian: Pelagic Regent). The locked loop order is still Glassfall, then Moonheld, then Lanternfall, then Glassfall again. Glassfall and Lanternfall have no plates yet. Moonheld is the six-panel chain. Sky Slivers spawn as occasional clusters of 3–6 along platform lines and jump arcs. A streak multiplier from x1 to x5 scales the score, shards fill a dash meter, and a double-tap on a full meter starts Overdrive. The run count, the results screen, and the lifetime total under `user://` stay. There is no shop. The first jump stays on `jump_8f`. The second jump plays the front flip, then the jump fall cells, then the existing landing. Overdrive plays its entry once and then its loop. Jump uses Thong's air-kick, `jump_air_opt1`. The web export stays single-threaded.

## Original proposal
Status was PROPOSED 2026-11-07, waiting on Thong's approval. The list below is that proposal. The header above is the build as it stands.

## Goal
A first playable that proves the core feel: run, jump, dash, kill. Nothing else.

## Engine / platform
- Godot 4.7, GL Compatibility renderer (same as Reincarnated as WHAT?!).
- Landscape. Web export for a phone test link first; iOS/Android export later.

## In scope
1. One world: Glassfall (locked v6 mock look; background parallax from existing Glassfall art).
2. One fighter: the pirate (locked lit cutout; at rest the arm is normal per Thong's rule; black coating + red-black lightning only during dash/attack, done as a code/shader effect, no new art).
3. Controls: left half tap = jump, tap again = double jump (air-kick sound), hold = glide; right half tap = dash.
4. Endless procedural platforms + gaps; speed ramps over time.
5. Dash-or-die monsters (placeholder shapes), hit-stop on kills, screen shake.
6. Score popups + visible combo counter.
7. Three lives per run, combined score; simple game over screen with restart.
8. Sounds: jump = air_kick opt1; dash, pirate attack, kill, death, tear warning from v1/v2 picks.
9. Placeholder UI where final UI art doesn't exist.

## Out of scope for v1
Guardians, Sky Slivers, world loop, other worlds/fighters, ads, leaderboard, goals/ranks/boosts, music, store builds.

## How it's built
- Cursor cloud agent in thongdo05/sora-tsunagi opens a PR; Thong merges.
- Every value (speed, gravity, jump height, dash length, hit-stop ms) in one tuning file.
- Art size: game-ready sprites only (downscaled); full-res concept art stays out of the repo until the storage decision.

## Done when
Thong can open the web build on his phone, play a run, and judge whether jump/dash/kill feel good.
