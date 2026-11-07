# Design Draft — Sora Tsunagi (空繋ぎ, working title)

**Owner:** Thong Do  
**Status:** First design draft; working title Sora Tsunagi (空繋ぎ, "mending the sky"; a coined title, pending native Japanese review and trademark clearance)  
**Date:** November 7, 2026 (America/New_York)

This is a new game, not **Reincarnated as WHAT?!** (Gon’s project) or **Kinetic Arm** (Mugi’s project). Confirmed direction is recorded below; unresolved mechanics and production decisions remain open.

## 1. Overview

An endless, side-scrolling jump-and-dash high-score game in the spirit of Robot Unicorn Attack, with anime fighting and monsters at its center.

- Simple two-zone touch inputs: **left side = jump, right side = dash** (locked 2026-11-07; see Core Gameplay Rules).
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

A teen with black hair. His stretch punch transforms his forearm and fist deep black, surrounded by red-and-black lightning. The black transformation must **not look like armor**: no armor plating or separate gauntlet; the arm and fist themselves change color. **At rest (running, jumping, idle, menus) both arms look completely normal and identical, with skin tone and no black, lightning or marks.** The black coating and lightning appear only during his dash and attack, then fade back to normal.

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

## 4A. Core Gameplay Rules (locked by Thong, 2026-11-07)

Adapted from a review of Robot Unicorn Attack 2 gameplay (reference only; copy no assets, names, or presentation). Tuning values are TBD.

- **Two-zone controls.** Tap the left half to jump, tap again in the air to double jump, and hold for a short glide (glide TBD in prototyping). Tap the right half to dash. Dashing into a monster fires the fighter's signature attack.
- **Dash-or-die monsters.** Some monsters and obstacles kill on contact unless you dash or attack through them. Each fighter's attack changes how these are handled: the pirate's shockwave can cover a near-miss, the swordsman's wave can clear them at range, and the ninja's wind deflects projectiles. Large "elite" monsters should demand a well-timed signature attack.
- **Hit-stop impact frames.** Big kills freeze for a split second with a white flash and high-contrast black/white silhouettes before the enemy shatters, in the style of a ufotable impact frame. This is the game's signature feel. Exact durations TBD.
- **Score popups and combo counter.** Points pop up where they're earned. Chaining kills and actions quickly builds a multiplier, shown on a visible combo counter in the HUD.
- **Three lives per run.** A run has three lives, and the scores from all three add up to one total for the leaderboard. Themed names for the lives TBD (must be original).
- **Goals, ranks and boosts.** Three active goals at a time. Completing them raises your rank, and ranks unlock rewards and features. Optional pre-run boosts (for example a pickup magnet) are bought with soft currency. Goal list, rank count, rewards and currency economy TBD.
- **Continue with a rewarded ad.** After a death, a short countdown offers a revive, either by watching a rewarded ad or (TBD) using premium currency. The revive happens where you died, with brief invulnerability. Limits per run and leaderboard fairness rules TBD.

- **Shards (pickup + soft currency).** Glowing fragments of the broken sky that spill from the rifts, laid out in arcs and lines that hint at the best jump/dash line. Collected Shards add score and are spent on boosts and unlocks. Ties to the "mending the sky" theme. Name: Sky Slivers (honey-gold); art v1 in `art/concepts/shards/final_v1/`. Values and economy TBD. (Spirit wisps and the ultimate-meter power pickup were not adopted for now.)
- **World loop (locked by Thong, 2026-11-07).** The run never ends at a guardian. Worlds cycle Glassfall, Moonheld, Lanternfall, then back to Glassfall, and each loop raises the stakes: speed keeps rising, guardians return with more weak points, faster telegraphs and denser attacks, the world looks more broken (more tears, darker sky, new monster mixes), and the score multiplier steps up each loop. A loop tag (e.g. "Glassfall II") shows depth. The run ends only on death. Loop scaling values TBD.
- **Rift Guardians (bosses).** At set score milestones the sky tears open, the music builds, and a Rift Guardian emerges. It runs ahead of the player along the track, throwing projectiles and hazards back. Glowing weak points on its body light up in turn; dash or attack into each one (with hit-stop on every hit). Break them all for a big kill frame and a score bonus, then speed rises and the run moves to the next world. Running never stops, and there is no separate arena or control scheme. Each fighter handles a guardian differently (the ninja deflects its shots, the swordsman hits weak points from range, the pirate's shockwave covers near-misses). Planned scope: one guardian per world at launch. **Locked designs (Thong, 2026-11-07):** Meridian Exile (Glassfall), Pelagic Regent (Moonheld), Veil Archon (Lanternfall), futuristic humanoid god beings; art in `art/concepts/guardians/final_v2/`. **Weak points are not drawn in the art.** They appear only in gameplay, as code/VFX overlays on the body parts the player must hit; use the planned heights in `docs/RIFT_GUARDIANS_SHARDS_PROPOSAL.md` (0.6 to 2.1 runner heights) as the reference. Kill-frame sheets in `guardians/final_v1/` use the old design and must be redone for v2 (paid, not approved). Milestone scores, weak point counts, and fail rules TBD.

**Not adopted / deferred:** RUA2's synthwave look; paid world unlocks, large currency grinds, and premium skips of goals (a monetization decision for later).

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
- Bosses: decided (Rift Guardians, see Section 4A). Elite mini-bosses between guardians: still open.
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

**OPEN:** Exact placements and formats, reward design if any, frequency, consent/privacy requirements, and the web-release monetization approach. A **rewarded-ad continue** is approved in principle (see Core Gameplay Rules). No other rewarded-ad, interstitial, or purchase behavior is approved by this draft.

## 9. Open Items and Approval Gates

- Working title and original character/attack names.
- MVP scope versus later content, including how three launch fighters fit the first playable milestone.
- Build plan, engine choice, animation tooling, and release packaging.
- Tuning for scoring, combos, difficulty progression, dash/jump/glide, hit-stop, revive limits, and character balance (the core rules are locked in Section 4A).
- Monster/enemy direction and counts: Thong to fill Section 6.
- World/environment direction and content: Thong to fill Section 7.
- Leaderboard implementation: confirm reuse details with Gon.
- Ad placements and monetization rules.
- Original-design/IP review before launch.
- **Cost approval before any paid generation**, including Higgsfield art and ElevenLabs audio. This document does not authorize spending or generation.
- Production schedule and budget: TBD. No performance, market, cost, or delivery-time numbers are asserted in this draft.
