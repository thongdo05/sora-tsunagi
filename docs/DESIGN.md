# Design Draft — Sora Tsunagi (空繋ぎ, working title)

**Owner:** Thong Do  
**Status:** First design draft; working title Sora Tsunagi (空繋ぎ, "mending the sky"; a coined title, pending native Japanese review and trademark clearance)  
**Date:** November 7, 2026 (America/New_York)

This is a new game, not **Reincarnated as WHAT?!** (Gon’s project) or **Kinetic Arm** (Mugi’s project). Confirmed direction is recorded below; unresolved mechanics and production decisions remain open.

## 1. Overview

An endless, side-scrolling jump-and-dash high-score game in the spirit of Robot Unicorn Attack, with anime fighting and monsters at its center.

- Simple, one-touch-style inputs: **jump + dash**. Exact input mapping is TBD.
- Dash is every character’s core movement and combat action.
- Dashing into a monster automatically activates the active character’s signature attack; no separate attack button is required. The swordsman’s wave specifically fires on every dash, before contact is necessary.
- Signature attacks must change how a run plays, not merely change its visual effects.
- Players chase a high score. Scoring formula, speed progression, failure rules, dash timing/cooldowns, jump behavior, and run structure details remain TBD.

## 2. Platforms and Format

**Orientation:** Landscape.

Release order:
1. Apple App Store.
2. Google Play.
3. CrazyGames or a similar web portal.

Approved account reuse:
- Thong’s existing Apple Developer account: **Individual**, Team ID **9589T6378Y**.
- Existing AdMob account: **playreincarnated@gmail.com**.

Thong approved both reuses. These are account identifiers, not login instructions; no passwords, keys, or tokens belong in this document or repository. Platform packaging and web-portal requirements remain part of the build plan.

## 3. Art and UX Direction

- **High-end, clean 2D anime — not pixel art.**
- Polished character animation, especially the transitions into and out of dashes, attack anticipation, impact, and signature-attack effects.
- Premium, clean UI/UX, with readable gameplay and minimal visual clutter.
- Recommended production approach, not yet a tool commitment: **skeletal 2D rigs (Spine-style) plus hand-made FX** for signature attacks.
- Effects should communicate the attack’s reach and behavior without hiding monsters, projectiles, or landing areas. Exact visual language and UI layouts remain to be designed.

**Art direction v2 (approved by Thong, 2026-11-07):** Kaito's proposal at `docs/ART_DIRECTION_PROPOSAL.md`. It draws on ufotable and Demon Slayer for a luminous, cinematic look: cel-shaded characters over richly painted, lit backgrounds, with moonlight and lantern light. It has its own effect language ("Inklight Fractures" for the tears, "Current Ribbons" for attacks) and explicit rules against copying Demon Slayer. Thong approved one Glassfall test image on Higgsfield. Any further paid generation still needs his cost approval.

## 4. Characters

**Launch roster direction:** Three fighters, inspired by One Piece, Naruto, and Bleach. Final names and visual designs must be original.

### Pirate — working archetype

A teen with black hair. His stretch punch transforms his forearm and fist deep black, surrounded by red-and-black lightning. The black transformation must **not look like armor**: no armor plating or separate gauntlet; the arm and fist themselves change color.

- **Signature:** Stretch punch; it needs direct impact to destroy enemies.
- **Unique trait:** A shockwave cracks the ground and knocks enemies back even when the punch misses.
- **Gameplay distinction:** Direct-hit destruction plus knockback on a miss. Shockwave reach, knockback strength, and any terrain interaction are TBD; visual ground cracks do not yet imply destructible terrain.

### Shinigami swordsman — working archetype

Black outfit and a sleek sword.

- **Signature:** A black energy wave fires from the sword on every dash.
- **Range identity:** The only fighter with a ranged attack; he can cut enemies before closing in.
- **Unique trait:** The wave ricochets off **one surface**, then detonates, enabling corner-angle attacks.
- **Gameplay distinction:** Pre-contact attacks and surface-angle play. Eligible surfaces, ricochet targeting, detonation trigger, blast size, and off-screen behavior are TBD.

### Ninja — working archetype

A spiraling ball of wind energy stays on his palm; it is not a launched projectile.

- **Signature:** A palm-first dash kills on contact.
- **Unique trait:** Deflects projectiles while the attack is active.
- **Gameplay distinction:** Contact combat combined with an active projectile-defense window. Window timing, deflection direction, and whether returned projectiles damage enemies are TBD.

### Mechanical comparison

| Fighter | Range | Strength | Weakness / constraint |
|---|---|---|---|
| Pirate | Extended melee stretch punch; exact reach TBD | Direct-hit destruction; missed punch still produces shockwave knockback | Needs impact to destroy; knockback alone is not confirmed lethal |
| Swordsman | Ranged wave; sole ranged fighter | Hits before closing; one ricochet and detonation reach corner angles | Ricochet limited to one surface; benefits depend on available geometry |
| Ninja | Palm-contact dash | Contact kill plus projectile deflection while active | Must close to contact; projectile protection is limited to the active window |

These are qualitative identities, not tuned balance values. Damage, hit rules, enemy exceptions, cooldowns, and character-specific scoring balance remain open.

**IP note:** The call’s names **Haki, Sengetsu, Rasengan, and Shinigami** are placeholder references to the source anime. Replace them with original names and distinct character, attack, costume, and effect designs before launch to avoid copyright and trademark problems. Renaming alone is not sufficient; obtain appropriate IP review rather than assuming the designs are cleared.

## 5. Leaderboard

A **global high-score leaderboard**, comparable in function to Reincarnated as WHAT?!’s. Reuse its technical setup, **not its visual appearance**.

**Implementation: TBD — confirm with Gon.** No backend implementation has been verified for this draft. Confirm the reusable architecture and permissions before integrating anything; do not modify the existing game or its backend while investigating.

Open decisions include score submission/validation, player identity and display names, ranking and ties, cross-platform behavior, and whether all fighters share one board. Reuse must preserve this game’s separate identity and avoid accidentally mixing its scores with the other game’s.

## 6. Monsters and Enemies — OPEN SECTION FOR THONG

No monster designs have been specified. Questions for Thong:

- What visual themes and tone should the monsters have?
- What sizes and silhouettes should appear?
- Which monsters, if any, use projectiles?
- Which enemies need different jump/dash timing?
- Should enemies have armor, multiple hits, or attack-specific interactions?
- Should bosses or elite monsters exist, or only regular enemies?
- What defeat effects and level of violence fit the intended audience?
- How many enemy types belong in the MVP versus later updates?

## 7. World and Environments

**Direction from Thong (2026-11-07):** the world is post-apocalyptic, showing the end of the world. Dimensional tears (portals ripping through space) are where the monsters and enemies come from, so the tears are both the main background element and the in-world reason enemies spawn.

**Art owner:** Kaito (game art designer) leads the visual design of the world. Thong's brief: it should look extremely beautiful, high-end and premium. That means clean 2D anime, not pixel art.

**Still open:**
- Biomes and zones (for example ruined cities or other areas) and how they change as a run goes on.
- How dimensional tears look, and whether they show up in gameplay (enemy spawns, hazards) or only in the background.
- Parallax layers, time of day, weather.
- Whether the world gets harder or changes visually as the score goes up.
- Any paid art generation needs Thong's cost approval first.

## 8. Monetization

**AdMob**, using the approved existing account above.

**OPEN:** Exact placements and formats, reward design if any, frequency, consent/privacy requirements, and the web-release monetization approach. No revive, rewarded-ad, interstitial, or purchase behavior is approved by this draft.

## 9. Open Items and Approval Gates

- Working title and original character/attack names.
- MVP scope versus later content, including how three launch fighters fit the first playable milestone.
- Build plan, engine choice, animation tooling, and release packaging.
- Scoring, difficulty progression, controls, failure rules, dash/jump tuning, and character balance.
- Monster/enemy direction and counts: Thong to fill Section 6.
- World/environment direction and content: Thong to fill Section 7.
- Leaderboard implementation: confirm reuse details with Gon.
- Ad placements and monetization rules.
- Original-design/IP review before launch.
- **Cost approval before any paid generation**, including Higgsfield art and ElevenLabs audio. This document does not authorize spending or generation.
- Production schedule and budget: TBD. No performance, market, cost, or delivery-time numbers are asserted in this draft.
