# Art Direction Proposal — Untitled Anime Dash Game

**For approval, not final art. Checked November 7, 2026 (ET). No generation or spending.**

## Source boundary

Read `DESIGN.md` in full and `README.md`, the project's only current files. Landscape is confirmed (Design §2); engine/build plan is open (§9), speed progression is TBD (§1). **Target resolution, camera framing/follow behavior and scroll speed are unspecified; no implementation/configuration exists here to verify them.** Do not inherit Godot, viewport dimensions, pixel rules or mechanics from Reincarnated as WHAT?!.

Standing preferences only from `/home/box/shared/game/reincarnation-shooter-context.md`: original IP, instant silhouette readability, fair visible danger, concise proposals before building, approval before animation/video, no guessed production numbers. All swatches and scroll factors below are **proposed art parameters**, not established settings or measurements.

## 1. Pillars and mood

- **Beautiful catastrophe:** luminous skies and monumental wreckage; sorrow and awe, not muddy rubble.
- **A fighter against infinity:** iconic silhouettes; jumps, dashes and impacts understood immediately.
- **Reality coming unstitched:** dimensional tears are the defining world image and consistent enemy-emergence language.
- **Premium restraint:** immaculate anime draftsmanship, selective spectacle and quiet space around action; genre energy without borrowed designs.

## 2. Master palette / contrast

| Role | Proposed hex swatches | Application |
|---|---|---|
| Sky / atmosphere | dusk `#687A9B`, mist `#AAB9C9`, horizon `#D9DDE1` | Broad, desaturated fields; avoid bright cloud rims behind combat |
| Ruin / world | slate `#596574`, stone `#858D98`, patina `#728C89` | Large masses, subdued material texture |
| Tear / void | abyss `#211C38`, violet `#8A67C8`, split-light `#D6BEFF` | Dark aperture, localized luminous incision |
| Player / friendly VFX | coral `#FF876D`, gold `#FFD18B`, ivory `#FFF1D8` | Small identity accents, directional strokes, impact cores |
| Hostile warning | rose `#EF507C`, warning light `#FFE4EA` | Reserved for imminent hostile action |
| Character separation | ink `#202938`, cool rim `#CAE4EB` | Contour and selective separation of black costumes/attacks |

Compress background contrast into quiet middle values; fade distant objects toward atmosphere. Keep near-black detail and near-white scenery out of the gameplay corridor. Fighters/enemies own the clearest dark/light boundaries. Black outfits and attacks need narrow pale edge separation, not a fog of bloom. Enemy designs remain open (Design §6); insist on distinct body silhouettes rather than color swaps.

Friendly VFX use directional strokes; hostile telegraphs use an inward notch/chevron and a visible emergence silhouette. Never rely on hue alone. Debris, foreground and friendly effects cannot hide monsters, projectiles, platform lips or landing spaces. Review grayscale and phone-size crops before approving detail.

## 3. Rendering

- Clean anti-aliased contours, not pixel stair-steps. Stronger outer silhouette, finer interior marks; defer pixel line-weight specifications until the display target exists.
- Cel shading: flat local color, decisive hard shadow shape, selective highlight. Avoid small tonal islands on moving subjects.
- Broad gradients in sky/haze; clean character and playable-surface planes. Glow uses a narrow core and restrained halo, never screen-wide bloom.
- Far layers may be softly painted, with detail reduced by haze. Midground becomes designed masses; gameplay layers have crisp edges and sparse texture. Beauty comes from composition, lighting and shape, not surface noise.
- Design §3 suggests rigged characters plus hand-made FX, not a locked tool. Original-design review must cover costumes, anatomy, weapons, poses and effects. The reference-like attack descriptions in §4 are **not visual clearance**: no copied symbols, recognizable character silhouettes, signature lightning, energy balls or waves. Renaming alone is insufficient.

## 4. Parallax — back to front

**Proposed relative factors:** `1.00` means gameplay-plane world/camera travel, not pixels per second. Tune after actual camera/run-speed testing.

| Layer | Proposed factor | Contents |
|---|---:|---|
| Sky | `0.00` | Quiet gradient/cloud field |
| Atmospheric veil | `0.08` | Haze bands, soft cloud sheets |
| Horizon monuments | `0.18` | Broken skyline, suspended structures |
| Distant tears | `0.28` | Muted atmospheric scars; no active-spawn warning marks |
| Midground ruins | `0.45` | Building shells, bridges, zone landmarks |
| Near environment | `0.72` | Simplified supports/vegetation outside action corridor |
| **Gameplay plane** | **`1.00`** | **Platforms, fighters, enemies, active tears and telegraphs** |
| Foreground framing | `1.12` | Sparse screen-edge silhouettes; never cross action/HUD |

An active tear and its hazard share world coordinates: no decorative-layer parallax displacing the telegraph. Composite warning marks above decorative FX; distinguish background scars from spawn tears in grayscale.

**Endless loops:** seamless horizontal sky/haze strips; interchangeable ruin modules with matching edge heights, light and palette. Separate occasional landmark modules from the base loop to soften repetition. Conceal joins through overlap away from landing edges; keep collision geometry independent of decorative rubble. Blend zones with shared transition modules and atmosphere, not sudden platform-edge changes. Test seams and density at representative run speeds before final painting.

## 5. Dimensional tears

**Shape:** asymmetric vertical wounds with offset angular lips, like a cut through layered glass—not circular magic gates, rune rings or recognizable anime emblems. A single strong aperture silhouette.

**Treatment:** thin pale-violet incision, restrained violet fringe, displaced slivers of local scenery; abyssal interior with sparse impossible-depth planes, not busy galaxy texture. Environmental scars stay muted; active tears acquire the notched hostile cue.

- **Open:** a stress crease contracts toward a notched emergence point, then parts. Reveal the enemy silhouette and emergence direction before entry into the action corridor. Timing needs gameplay tuning, not an invented duration.
- **Idle:** restrained edge tension/local distortion. No warning-like pulsing unless a spawn is pending; decorative tears must acquire the active state before spawning.
- **Enemy emergence:** silhouette, clear body contour, then movement into play. Particles stay behind the body; no concealed projectile launches or light masking a landing edge.
- **Close:** lips fold inward, incision collapses, slivers dim in place. No full-screen flash or effect resembling an attack.

Design §7 leaves gameplay tear placement/hazards open. This is a proposed spawn-telegraph treatment, not approval of portal damage or surprise spawns.

## 6. Zone concepts — proposals, not launch scope

| Zone | Hook / palette shift | Landmark silhouettes | Unique tear behavior |
|---|---|---|---|
| **Glassfall Metropolis** | The last sunset through an emptied city. Dusty peach sky `#B89A9B`, slate ruins, violet wounds. | Split observation towers, hanging transit spans, roof-garden silhouettes | Window reflections misalign, then facade fragments displace around a vertical seam without masking its cue |
| **The Suspended Sea** | An abandoned coast beneath a sea torn into the sky. Sea-glass atmosphere `#85A8AC`, cool stone `#758393`. | Dry harbor pylons, stranded hulls, distant suspended water shelves | Horizon/droplets bend toward a pressure crease; dark aperture keeps the standard cue readable against pale water |
| **Ashlight Conservatory** | A ruined botanical district blooms under impossible dawn. Lilac haze `#A29CB1`, sage world `#788A80`. | Broken greenhouse ribs, petrified canopies, leaning irrigation arches | Petal-like debris suspends and separates along a folded slit; clears before the emergence silhouette appears |

All zones retain the same hostile-warning grammar. Variation is environmental behavior, not unexplained danger signals. Weather/debris stay out of the action corridor.

## 7. Next steps / real cost check

1. Approve direction; propose Glassfall as the first test. Confirm engine, resolution/framing, camera and representative speed before production-sized art.
2. Proposed static concept set: Glassfall landscape keyframe with a quiet gameplay lane; matching readability plate with original fighter/enemy placeholders and an active tear; comparison sheet for Suspended Sea and Ashlight. Approve the first keyframe before expanding the batch. No images made yet.
3. Validate grayscale/phone-size silhouettes, then define tile boundaries, layer exports and tear-state sheet. Animation/video and paid generation each require Thong's explicit approval; cost approval is not implied by this proposal.

### Read-only Higgsfield findings — November 7, 2026 (ET)

- `user-Higgsfield.models_explore` (`recommend`, then `get` for `recraft_v4_1` and `soul_location`): **Recraft V4.1 standard** is a suitable illustration-concept candidate with palette controls; **Soul Location** is environment-focused. This is a suitability proposal, not tested quality. Both list landscape output. **Neither exposes per-image model credit pricing.**
- `user-Higgsfield.balance`: **4,524.24 credits; creator plan.** Model responses say unlimited allowance is unavailable; do not assume free generation.
- `user-Higgsfield.marketing_studio_v2_costs`: **3.75 credits** for its `poster` image workflow, `reference_or_text_only` scenario. This is a workflow price, **not** a verified Recraft V4.1 or Soul Location model price; it cannot honestly price this concept set.

**Requested model-based cost estimate: unavailable.** No verified per-image model cost means no defensible batch-credit or cash estimate. Obtain a read-only quote tied to the selected model/configuration before seeking spend approval. No generate, reserve, purchase or billing tool was called.
