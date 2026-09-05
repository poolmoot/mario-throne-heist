# Mario: Throne Heist — Game Design

## Purpose

Build a private, non-commercial fan-game prototype that runs directly on an Arduino Uno Q
with 4 GB RAM and a 5-inch touchscreen. Mario has two minutes to infiltrate a compact
Imperial palace, claim a throne, and escape while pursued by Stormtroopers.

The game combines readable third-person stealth with a short arcade structure. It does not
attempt to reproduce Hitman's simulation depth. Mario, Stormtroopers, and lightsabers are
third-party intellectual property, so the prototype is not intended for commercial release
or public distribution. No ripped game assets will be included.

## Target Hardware

- Arduino Uno Q, 4 GB RAM
- 5-inch 800×480 display with touch input
- One Modulino Joystick
- One Modulino Buttons module with buttons A, B, and C
- One Modulino Light
- One Modulino Vibro

The game must remain fully playable with the joystick, buttons, and light sensor. Touch is
limited to menus and is not required during the mission.

## Player Experience

The player should understand the objective and danger at a glance on the small display.
Each run is short enough to encourage learning patrol routes and retrying for a better
score. The mood is playful space fantasy rather than realistic violence.

### Complete Flow

1. The title menu accepts touch or button A.
2. A 2–3 second setup screen calibrates the uncovered light sensor.
3. A short mission briefing shows the throne, exit, controls, and objective. The timer is
   stopped during menus and briefing.
4. The two-minute timer starts when Mario crosses the starting gate.
5. Mario infiltrates through either the royal kitchen or garden route.
6. Walking onto the throne claims it automatically. The throne shrinks and floats above
   Mario's head.
7. Claiming the throne stops the acquisition timer, removes any disguise, starts the escape
   timer used for scoring, closes the original entrance, opens a new drawbridge route, and
   puts the palace into lockdown.
8. Mario reaches the marked exit to complete the mission.
9. The results screen shows acquisition time, escape time, detections, and lightsabers
   thrown, then offers retry and quit.

Failing to acquire the throne before two minutes or being caught ends the run. Restarting
must be fast and return directly to the briefing/start sequence.

## Controls

- Joystick: move Mario.
- Button A: interact, collect items, and use contextual objects.
- Button B: equip or remove a Stormtrooper disguise.
- Button C: crouch and move quietly.
- Cover then uncover Modulino Light: throw the lightsaber.
- Touchscreen: title, pause, settings, and results menus only.

The camera follows Mario automatically, rotates toward sustained movement, frames nearby
objectives, and avoids level geometry. It must not hide nearby guards or their vision cones.
All menus must also support joystick navigation and button A confirmation.

## Lightsaber and Sensor

At mission start, the bridge records the ambient-light baseline while the sensor is
uncovered. A valid throw requires a deliberate covered interval followed by a stable return
toward the baseline. Hysteresis, minimum hold duration, and a cooldown prevent room-light
changes from producing accidental throws.

The lightsaber travels forward with mild target assistance, stops at the first guard or
solid wall, and never pierces or damages multiple guards. A hit removes one Stormtrooper in
a smoke burst with dropped empty armor and no graphic violence. A miss still creates noise.
Nearby guards become suspicious or alerted when a throw is seen or heard. The lightsaber
returns to Mario after a hit or miss, and another throw is unavailable until it returns.

The HUD shows sensor states: ready, covered/charging, thrown, and cooling down. Development
builds provide a keyboard fallback for sensor input.

## Vibration

- Medium pulse when the sensor gesture releases a lightsaber.
- Strong pulse on lightsaber impact.
- Short warning pulse when Mario becomes detected.

Missing vibration hardware must not block input or gameplay. Haptic requests are best-effort
and rate-limited.

## Stealth and Guards

The first level contains three to five active Stormtroopers. Each follows a authored patrol
and uses a small state machine:

- Unaware: no icon; neutral vision cone.
- Suspicious: yellow question mark; investigates a sound or partial sighting.
- Alerted: red exclamation mark; moves toward Mario's last observed position.
- Searching: checks the last-seen area after line of sight breaks.

Vision uses line-of-sight checks against level geometry. Guards never track Mario through
walls. Ground-projected cones change from neutral to yellow to red and remain high contrast
at 800×480. After the throne is claimed, all remaining guards enter lockdown, but they still
need line of sight to update Mario's location.

A disguise allows Mario to pass ordinary guards at a distance. Crouching, throwing the
lightsaber, entering restricted throne space, or approaching an elite guard too closely
breaks the disguise.

## World and Art Direction

The Sunkeep is a bright, low-poly storybook Imperial palace on a small planet. Warm stone,
deep-green hedges, blue water, gold architecture, red banners, spacecraft, and distant
planets create a readable space-fantasy identity.

The compact level forms a loop rather than a corridor:

- Starting overlook: shows the throne landmark and eventual exit.
- Outer courtyard: teaches cover, patrols, and vision cones.
- Royal kitchen route: supports disguise play and guarded doors.
- Garden route: supports crouching, hedges, statues, and shortcuts.
- Throne courtyard: an open circular space with a raised golden throne and elite guards.
- Drawbridge escape: opens during lockdown and changes the return path.

Distant structures are silhouettes or simple meshes. Only playable areas receive collision,
navigation, and detailed props.

Mario and Stormtrooper models will initially be replaceable placeholders. User-provided
assets will be imported later behind stable player/enemy scene interfaces. Model scale,
forward axis, animation names, skeleton differences, and material complexity must be
normalized in dedicated visual-wrapper scenes rather than leaking into gameplay scripts.

## Five-Inch Display UI

- Design resolution is exactly 800×480.
- Critical HUD elements remain inside generous safe margins.
- The two-minute timer is the largest text element.
- Alert icons, objective markers, and sensor state use shape and color together.
- Body text is brief and large; gameplay never relies on paragraphs.
- Touch targets are at least 48×48 logical pixels with ample spacing.
- Transparent vision cones are tuned for contrast without obscuring characters.
- Menus remain operable using the physical controls if touch is unavailable.

## Technical Architecture

The project starts from Summer Engine's `3d-third-person-controller` template. Existing
controller and camera code is adapted rather than replaced wholesale. Demo weapons, enemies,
and presentation chrome not used by this game are removed from the runtime scene.

Focused systems:

- `GameFlow`: briefing, infiltration, throne acquisition, lockdown, escape, results, and
  restart.
- `MissionTimer`: authoritative two-minute acquisition timer and separate escape stopwatch.
- `PlayerController`: movement, crouch, interaction, disguise, and throw requests.
- `AutoFollowCamera`: single-stick framing and obstruction handling.
- `GuardController`: guard state machine composed with separate sight and hearing sensors.
- `Throne`: acquisition trigger and floating carried visual.
- `Lightsaber`: one-target projectile, return path, noise, and cooldown.
- `HardwareInput`: normalizes keyboard and injected Modulino inputs into game actions.
- `HUD` and menus: small-screen mission feedback and touch/physical navigation.

The game receives hardware gestures as ordinary input events. The Uno Q bridge is extended
to recognize `ModulinoLight` at I²C address `0x53`, publish ambient light readings, detect
the calibrated cover-release gesture, inject the configured throw action, and invoke
`ModulinoVibro`. Hardware-specific code remains outside gameplay scenes.

## Uno Q Performance Budget

- Compatibility renderer only.
- 800×480 viewport with viewport stretching and a 60 FPS cap.
- ETC2/ASTC texture imports and Linux ARM64 release export.
- One 1024px directional shadow; no shadow-casting point or spot lights.
- No MSAA, screen-space reflections, volumetrics, or dense transparent foliage.
- Mostly 512px textures, with 1024px reserved for shared atlases where justified.
- Five active guards maximum.
- Baked navigation and throttled guard perception checks.
- Reused/poolable lightsaber and smoke effects with strict particle limits.
- Simple collision shapes and minimal transparent overdraw.
- Runtime memory target below approximately 1 GB, leaving headroom for Linux, App Lab,
  and the game container.

## Failure Handling

- Sensor missing: show a non-blocking hardware warning and retain the development fallback.
- Calibration invalid: retry calibration without starting the mission timer.
- Vibro missing or RPC failure: continue silently after recording a diagnostic.
- Asset missing or incompatible: keep the placeholder visual and report the import issue.
- Guard navigation failure: stop safely and return to the nearest valid navigation point.
- Timer expiry or player capture: transition once to failure and ignore duplicate events.

## Verification

Automated tests cover timer transitions, throne acquisition, lightsaber single-target
behavior, guard state changes, disguise-breaking actions, and mission success/failure.

Editor verification covers automatic camera visibility, both infiltration routes, menus
without a mouse, alert readability at 800×480, quick restart, and placeholder asset swaps.

Hardware verification on the Uno Q covers light calibration under multiple room conditions,
false-trigger resistance, vibration patterns, touch targets, all physical controls, ARM64
export, frame pacing, memory use, and a complete acquire-and-escape run on the 5-inch
display. The game is not considered hardware-ready until it has been played on the board.
