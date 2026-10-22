# Ace Golf: decisions, open questions, MVP scope, plan

Grilling session 2026-10-22. First round: Golfclub Prenden (18-hole course), 2026-10-23.

## Decisions

| # | Topic | Decision |
|---|-------|----------|
| 1 | Goal | Something usable on the phone tomorrow. Target is Ace parity, built in cuttable phases. Everything beyond Ace is post-round. |
| 2 | Map | Apple MapKit, satellite (`.imagery`). Committed, no map abstraction layer. Course model and geometry live in a MapKit-free Swift package. |
| 3 | Licence | AGPL-3.0 with a section 7 additional permission for App Store distribution. Clean reimplementation of Ace's logic in Swift; Ace credited as inspiration. OSM attribution visible in app; bundled extracts in `data/` under ODbL. |
| 4 | Data path (round 1) | Mac-side extractor queries Overpass (retries across mirrors), emits one normalized JSON per course plus a GPX walk. App reads bundled JSON only. No network code in the app tomorrow. |
| 5 | Multi-course | Prenden has two numbered layouts in one area. Round 1: extractor takes an explicit list of the 18 hole-line way IDs. General disambiguation (separate polygons, relations, tags, spatial clustering) is post-round. |
| 6 | Rotation | Camera heading = chord bearing from first to last point of the hole line; camera fitted to the hole's feature bounding box. No rotate-from-position. |
| 7 | Front/middle/back | Middle = green polygon centroid. Front/back = green boundary vertices with min/max projection onto the player→centroid line. Great-circle metres, no elevation. |
| 8 | Tees | No tee selection. Hole line start is the reference tee. Tee pads drawn as overlays only. |
| 9 | Hole switching | Manual: prev/next buttons and scorecard tap. Opens on hole 1. Auto-advance later. |
| 10 | Location | `CLLocationManager`, best accuracy, `.fitness`, no smoothing. Accuracy ring drawn; distances dimmed with a label when horizontal accuracy > 15 m. Foreground only, When In Use permission, no background mode. Every fix logged to a file. |
| 11 | Scorecard | In, as the last and cuttable phase. 18 holes, par from OSM when tagged, tap-to-increment, total and to-par, persisted as a round JSON file. |
| 12 | Elevation | Out for round 1. Later: pre-baked by the extractor from Brandenburg's open 1 m terrain model, not fetched live. |
| 13 | Testing | Unit tests on the pure geometry package. Extractor-generated GPX walk of all 18 holes played through Xcode location simulation as tonight's acceptance test. Real round's location log becomes fixture two. |
| 14 | Distribution | Xcode sideload to the paired iPhone 17 Pro with the Apple Development cert. Public GitHub monorepo (app, geometry package, extractor, data) from commit one. TestFlight/App Store later if ever. |
| 15 | Shot tracking | Post-round. Phase one is one-tap manual "mark". Automatic detection comes with the Bangle.js watch. Round file has a `shots` array per hole from day one, empty tomorrow. |
| 16 | Post-round priority | (1) in-app Overpass fetch + cache + multi-course disambiguation, (2) manual shot marking, (3) pre-baked elevation, (4) Bangle.js companion, (5) swing analysis. |
| 17 | Differentiator | One open pipeline (course data, rounds, shots, watch) that the user controls. Sufficient for a personal tool; not yet a reason for anyone to leave SwingU, and we say so. |

## Facts established

- Ace is one 1,300-line TypeScript file. Overpass within 5 km of course centroid, filtered to the course polygon, features assigned to nearest `golf=hole` line within 100 m, chord bearing, Esri imagery and elevation, `localStorage` cache keyed by course name, holes fixed 1–18, no F/M/B, no shots, no tee selection.
- Pankow OSM data: duplicate hole refs across layouts, most holes lack `par`, hole 10 tagged par 6, tees and greens untagged.
- Prenden OSM data (from osm.org render): hole lines with refs, tee pads, greens, fairways, bunkers, water; dog-leg on hole 8; an 18-hole layout and a second 1–8+ layout along the A11.
- Public Overpass: all five endpoints tried were at capacity or timing out for ten minutes on 2026-10-22. Not a live dependency for round 1.
- Toolchain: Xcode 26.5, iOS 26.5 SDK, Apple Development cert on a paid team, iPhone 17 Pro paired.

## Open questions

1. Apple satellite imagery zoom over Prenden (user checks in Apple Maps tonight). If blurry below ~z17, revisit imagery.
2. Do Prenden's hole ways carry `par` / `handicap`? Are the two layouts separate `leisure=golf_course` polygons or relations? (Extractor will report.)
3. Does every hole line start on a tee pad and end on the green? (Extractor sanity check; hand-fix if not.)
4. Minimum deployment target: proposed iOS 18 (SwiftUI `Map` with `MapPolygon`, `MapCamera` heading, `MapReader` tap conversion all need iOS 17+). Phone is on iOS 26.
5. App name and bundle id (proposed: `AceGolf`, `com.jamesfarrell.acegolf`; rename later).

## MVP scope for round 1 (tomorrow)

In: satellite map rotated per hole with green/tee/fairway/bunker/water overlays, hole prev/next, live position with accuracy ring, front/middle/back to green in metres, tap-to-measure, location log, scorecard with par and to-par (cuttable), About screen with OSM attribution.

Out: Overpass in the app, course auto-detection, elevation, shot tracking, hazard distances, tee selection, auto hole advance, background location, watch, swing analysis.

## Architecture

```
ace-golf/
  LICENSE                      AGPL-3.0 + App Store additional permission
  README.md                    what it is, Ace credit, OSM/ODbL attribution
  AceGolf/                     Xcode app (SwiftUI, iOS 18+)
    App/                       entry, navigation
    Course/                    CourseStore (loads bundled JSON)
    Location/                  LocationService (CLLocationManager → fixes + log file)
    Hole/                      HoleView (Map, overlays, camera), DistancePanel, TapMeasure
    Scorecard/                 ScorecardView, RoundStore (round JSON)
    Resources/                 bundled data/courses/*.json
  Packages/GolfCore/           Swift package, no MapKit/CoreLocation
    Models: Course, Hole, Round (Codable, versioned)
    Geometry: haversine, bearing, centroid, frontMiddleBack, boundingBox, nearestHole
    Tests
  tools/extract/               Python extractor
    extract.py                 Overpass (mirror retry) → normalized course JSON + GPX walk
  data/
    courses/prenden.json       ODbL notice in data/README.md
    tracks/prenden-walk.gpx
  docs/DECISIONS.md            this file
```

Course JSON (v1): `{ schema: 1, id, name, osm: {courseWay, holeWays[]}, polygon, holes: [{ number, par?, handicap?, line: [[lon,lat]], green: polygon, tees: [polygon], fairways: [polygon], bunkers: [polygon], water: [polygon] }] }`

Round JSON (v1): `{ schema: 1, courseId, startedAt, holes: [{ number, strokes?, shots: [{ t, lat, lon, acc }] }] }`

Location log: JSON lines, one fix per line: `{ t, lat, lon, acc, alt?, speed? }`.

## Plan for tonight (phases, in order, each independently shippable)

0. **Scaffold (30 min).** git init, LICENSE, README, Xcode project, GolfCore package with empty models, bundle id, When In Use usage string, run on device once.
1. **Data + geometry (90 min).** Extractor: list candidate hole ways with ref and centroid for the user to pick 18 IDs; then emit `prenden.json` and `prenden-walk.gpx`. GolfCore models + geometry with unit tests (F/M/B from three sides of a square green, chord bearing on straight and dog-leg lines, nearest-hole tie case).
2. **Hole map (2 h).** Satellite `Map`, overlays from course JSON, chord-bearing camera fitted to hole bounds, prev/next hole, hole number and par in the header.
3. **Live distances (60 min).** LocationService with log file, user dot and accuracy ring, front/middle/back panel in large type, tap-to-measure with a dropped pin, dimming when accuracy > 15 m.
4. **Scorecard (60 min, cuttable).** 18-hole strip, tap to load hole, +/- strokes, total and to-par, round JSON persisted.
5. **Acceptance (30 min).** Play `prenden-walk.gpx` through the simulator and the device; walk hole 1 and hole 8; install final build on the phone; About screen with OSM attribution.

User tasks tonight: Apple Maps zoom check over Prenden; pick the 18 hole-line way IDs from the extractor's candidate list.

## Status after the build evening (2026-10-22)

All six round-one tickets merged to `main` (PRs #1 to #6). The app is installed on the iPhone 17 Pro from `main` at `72876c8`.

Shipped: satellite hole map with overlays and chord rotation, prev/next, live position with accuracy ring, front/middle/back, tap-to-measure, location log (Documents/logs/*.jsonl), About with ODbL attribution, scorecard with round file (Documents/rounds/*.json, empty `shots` per hole).

Verified in the simulator with a simulated walk of hole 1; GolfCore has 24 passing tests. Not yet verified: a real outdoor GPS fix, and the dimmed-values state (the simulator always reports 5 m accuracy).

Calibration note: MapKit's visible ground height at pitch 0 is about 0.58 × camera distance on an iPhone 17 Pro. `HoleCamera` uses that to fit each hole between the header and the bottom panels.

Tomorrow after the round: copy `Documents/logs/*.jsonl` and `Documents/rounds/*.json` off the phone (Finder → iPhone → Files → Ace Golf) into `data/tracks/` as the first real fixtures. Note what annoyed you on the course before reading the backlog.

OSM fixes to contribute back at Prenden: tee names "Abschlah weiß", "Abschlag Rot1", and a tee tagged "Drope Zone" (probably a drop zone, not a tee).

Tooling notes: use Homebrew Python 3.13 for the extractor (Xcode's 3.9 has a TLS failure against overpass-api.de); `simctl location start` needs waypoints on stdin from zsh; the `exponential` CLI must be run with `HOME=/Users/james/.config/agent-homes/claude`.
