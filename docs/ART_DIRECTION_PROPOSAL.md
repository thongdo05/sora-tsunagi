# Art Direction Proposal v2 — Untitled Anime Dash Game

**November 7, 2026 (ET). Proposal, not final art. No generation or spending.**  
Previous version preserved unchanged as `ART_DIRECTION_PROPOSAL_v1.md`.

## Direction / source boundary

Thong’s new direction: draw inspiration from ufotable and Demon Slayer. **Replace the muted v1 treatment with luminous, saturated cinematic anime:** hand-drawn cel figures against richly lit painted/composited environments. Take craft principles, never franchise assets or designs.

Research grounding: in [Crunchyroll’s interview with director Haruo Sotozaki and photography/finishing director Yuichi Terao](https://www.crunchyroll.com/news/interviews/2025/7/27/demon-slayer-kimetsu-no-yaiba-infinity-castle-staff-interview-climax-and-working-as-one), Terao describes assembling character animation, backgrounds and 3D assets, then unifying color, lighting and atmospheric effects. He also warns that overpowering orange can distract from the drama. [Anime News Network’s Terao interview](https://www.animenewsnetwork.com/feature/2018-01-10/interview-yuichi-terao-chief-of-ufotable-digital-team/.125658), found in the same search, discusses blending through lighting. **Our translation:** compose light around the action, not on top of it. The specific treatments below are our proposals, not claims about a mandatory studio recipe.

Project facts remain as recorded in v1 from `DESIGN.md` and `README.md`: landscape confirmed (§2); engine/build plan open (§9), speed progression TBD (§1); resolution, camera and actual scroll speed unspecified. Do not inherit the other game’s viewport, engine or pixel-art rules. Standing preferences: original IP, instant silhouettes, readable danger, no guessed production numbers, approval before animation/video. All hex values and scroll factors below are **proposed art parameters**.

## 1. Pillars / mood

- **Luminous apocalypse:** saturated midnight and violet dusk, moon-silver edges and amber lights surviving among monumental ruins.
- **Ink against cinematic depth:** bold cel silhouettes inhabit almost photographic painted/composited space, unified by key light and atmosphere.
- **Reality as a torn print:** dimensional wounds shear the world into ink-dark layers and luminous registration offsets.
- **Spectacle with clarity:** beauty surrounds a calm gameplay lane; every jump, dash, enemy and hazard reads immediately.

## 2. Master palette / value rules

| Role | Proposed hex swatches | Use |
|---|---|---|
| Sky / atmosphere | midnight `#162A67`, electric dusk `#6339A6`, moon haze `#8ABCEB` | Saturated upper skies and deep atmospheric separation |
| Ruin / world | indigo stone `#344774`, petrol teal `#276B79`, lit masonry `#8098C4` | Cool structural masses; illuminated planes, not evenly bright texture |
| Environmental light | lantern amber `#FFB34F`, moon silver `#D7EDFF` | Volumetric shafts, pools of light, selective source bloom |
| Tear / void | ink void `#170D2C`, fracture violet `#B45CFF`, ice seam `#A7F3FF` | Dark cut bordered by luminous displaced edges |
| Player / friendly VFX | vermilion `#FF7058`, warm gold `#FFD275`, ivory `#FFF1D8` | Warm identity accents, clear attack leading edges |
| Hostile telegraph | warning rose `#F34F93`, pale warning `#FFE0EF` | Imminent threat only; reinforced by notches and silhouettes |
| Character contour | blue-black `#111B35`, separation rim `#C2E9FF` | Varied ink contour; local separation for dark costumes/attacks |

**Saturation is not permission for visual noise.** Keep broad, calm value fields immediately behind the action; move dramatic brightest shafts, dense texture and deepest scenery blacks above/below the lane. Compress local background contrast there without desaturating the whole world. Moon/lantern key light gives actors crisp separation; a black fighter gets a selective rim, not an all-body halo. Darken or simplify scenery locally when an enemy silhouette would disappear.

Friendly attacks use forward-flowing tapered ribbons; hostile warnings use inward notches and an emergence silhouette. Never rely on color alone. Bloom, rain, dust, distortion and friendly FX cannot hide projectiles, monsters, platform lips or landing spaces. Review grayscale and phone-size crops, including the darkest fighter against each zone.

## 3. Rendering / compositing

- **Characters:** hand-drawn-looking cel figures with bold, varied line weight—weighted shadow-side contour, finer light-side/internal marks. Flat local color, hard shadow masses, selected highlights. Defer pixel line-weight specifications until the display target exists.
- **World:** richly painted skies/materials and perspective-coherent ruins; optional 3D-assisted background plates, not a requirement to build a live 3D world. Almost photographic lighting/depth, but authored anime shapes and no stock-photo collage look.
- **Composite:** color-graded night/dusk; atmospheric distance, moon and lantern key lights, volumetric shafts and bloom on actual sources. Match actor light direction and contact shadows to scenery. Keep shafts behind actors; suppress halos near telegraphs. No whole-screen grading that erases warning distinctions.
- **Layer detail:** richest painterly detail in distant landmark plates, softened by depth/haze; simplified near masses; crisp, clean cel gameplay layers. Reserve high-frequency contour detail for actors and actionable edges.
- **Attack language — “Current Ribbons”:** ukiyo-e-informed flowing contours, flat overlapping color bands, carved-ink edges and tapered trailing splinters. Contact attacks form short pressure folds; ranged attacks form a directional folded sheet; deflection forms a compact hooked curl. The bright leading edge communicates reach; trailing ornament dissipates behind it. No copied wave/flame choreography, water-dragon shapes or screen-filling decorative trails. Mechanical reach still follows approved gameplay, not concept art.

## 4. Parallax — back to front

Factors are **proposed relative travel**, not measured speed; `1.00` is the gameplay plane. Tune once camera/run-speed tests exist.

| Layer | Proposed factor | Treatment / content |
|---|---:|---|
| Sky | `0.00` | Saturated painted night/dusk vault; dramatic cloud light above lane |
| Atmosphere | `0.08` | Composited haze and depth-separated shafts behind action |
| Horizon monuments | `0.18` | Rich painted or 3D-assisted ruin plates; moon/lantern light |
| Distant fractures | `0.28` | Luminous ink scars, softened by depth; no spawn-warning marks |
| Midground ruins | `0.45` | Lit shells, water/reflection plates and zone landmarks |
| Near environment | `0.72` | Simplified architecture/vegetation, calm values behind lane |
| **Gameplay plane** | **`1.00`** | **Cel fighters/enemies, platforms, active tears and telegraphs** |
| Foreground frame | `1.12` | Sparse edge-only silhouettes; never sweep over action/HUD |

Keep active tears and their telegraphs in the same world coordinates as hazards. Composite warnings above decorative FX. Bake painted light into repeatable plates where practical; keep any separate light overlays aligned with their sources. This is an art-layer plan, not an engine/performance commitment.

**Endless tiling:** seamless sky/haze strips; modular architecture with matching joins, light direction and grading. Separate rare landmarks from base loops. Do not bake unique giant shafts across repeat seams. Hide joins through overlap away from landing edges; collision stays independent of decorative rubble. Transition zones through shared light/atmosphere modules without changing platform-edge readability. Test repetition and seams at representative speeds before final painting.

## 5. Dimensional tears — “Inklight Fractures”

An asymmetric upright cut through a printed world: angular ink-dark lips, stepped/carved edges and offset violet/cyan light contours, like misregistered print layers. Interior: sparse inverted planes sinking into near-black, not galaxy wallpaper or a circular rune gate. The edges borrow woodblock mark-making, not any franchise’s effects.

- **Open:** a compressed ink crease splits; offset light bands peel apart around a notched emergence point. Show enemy silhouette and direction before entry. Timing awaits gameplay tuning.
- **Idle:** slow slip between edge layers and localized light leakage. Decorative tears lack hostile notches and warning pulses; they must acquire the active cue before spawning.
- **Emergence:** silhouette, clear body contour, then movement into play. Fracture ribbons/debris stay behind the enemy; no concealed projectile launches or obscured landings.
- **Close:** separated print layers align, light retracts into the seam, ink lips shut. No blinding flash or closure that resembles an attack.

Background fractures may be spectacular away from the lane; active spawn tears prioritize the warning. Tear damage/placement remains unapproved (Design §7).

## 6. Zones — proposed, not launch scope

| Zone | Hook / palette shift | Landmark silhouettes | Tear behavior |
|---|---|---|---|
| **Glassfall Afterglow** | A dead metropolis holds the last furnace-colored sunset. Violet `#6339A6`, ember `#FF9357`, indigo stone. | Split observation towers, hanging transit spans, glowing emergency lanterns | Facade reflections separate into offset print bands before the ink seam opens |
| **The Moonheld Sea** | An abandoned coast beneath suspended ocean shelves. Cobalt `#204B9C`, turquoise `#38A5BC`, moon silver. | Dry harbor pylons, stranded hulls, immense remote water shelves | Moonlit reflections bend inward; carved contour ribbons expose the dark aperture while the standard notch stays clear |
| **Lanternfall Conservatory** | Broken botanical halls keep glowing through an endless violet night. Plum `#482361`, jade `#278778`, lantern amber. | Shattered greenhouse ribs, petrified canopies, suspended maintenance lights | Leaf-like ink slivers hang, then peel from a luminous fold; debris clears before the enemy silhouette appears |

Same hostile grammar everywhere; differences are environmental motion, not unexplained danger cues. No recognisable franchise locations or compositions.

## 7. Originality guardrails

No Demon Slayer character designs, haori patterns (checkered, hexagonal or flame-cape motifs), Breathing-style named techniques, Nichirin-blade color coding, demon designs or recognizable scenes. No lookalikes, symbols or signature effects from the other named reference properties either. Use the broad ukiyo-e/public-domain woodblock tradition—such as Hokusai’s waves—for contour rhythm and layered shapes, not a specific anime effect or a traced composition. Verify rights for any particular reference reproduction used.

Our identity is **Inklight Fractures + Current Ribbons**: printed-space misalignment for tears, directional pressure-fold ribbons for combat. Review original costumes, anatomy, silhouettes, names and effect choreography; renaming borrowed designs is not enough. Design §4’s reference-like descriptions are not visual clearance.

## 8. Next steps / cost gate

Approve the revised proposal, then confirm engine, resolution/framing, camera and representative speed. Proposed first static concept: Glassfall Afterglow with luminous composited scenery and a calm cel-action lane; approve that sample before a readability plate and zone comparison sheet. Validate grayscale/phone-size silhouettes before production assets. No images, animation or video made by this revision.

**Historical read-only cost check from v1, November 7, 2026 (ET); not refreshed for v2:** Higgsfield `models_explore` supplied no per-image price for Recraft V4.1 or Soul Location; `balance` returned **4,524.24 credits**, creator plan. `marketing_studio_v2_costs` quoted **3.75 credits** for the poster workflow, not those model configurations. Therefore model-based concept costs remain **unverified**, not a batch estimate or current balance guarantee. Obtain a configuration-specific read-only quote and Thong’s explicit cost approval before any paid generation. No credits spent or reserved.
