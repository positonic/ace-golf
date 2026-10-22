# Ace Golf

A native iOS golf GPS app built on open data. Satellite hole maps from Apple MapKit, course features (tees, greens, fairways, bunkers, water) from [OpenStreetMap](https://www.openstreetmap.org), front/middle/back distances to the green, tap-to-measure, a location log of every round, and a simple scorecard.

The aim is an open pipeline you control: course data, rounds and shots live as plain files in your own storage, and the same model will feed a Bangle.js watch companion and swing analysis later.

Modelled on [Ace](https://github.com/bdlucas1/ace) by Bruce Lucas, an open-source browser golf app. Ace Golf is a clean reimplementation in Swift, not a port; Ace's ideas are gratefully acknowledged.

## Layout

```
AceGolf/            SwiftUI iOS app (iOS 18+)
Packages/GolfCore/  Swift package: course, hole and round models and pure geometry. No MapKit, no CoreLocation.
tools/extract/      Mac-side extractor: OpenStreetMap (Overpass) -> normalized course JSON + GPX walk
data/courses/       Bundled course extracts (ODbL, see data/README.md)
data/tracks/        GPX tracks for Xcode location simulation
docs/               Decisions and plans
```

## Build

Requires Xcode 26 and [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`).

```bash
xcodegen generate
open AceGolf.xcodeproj
```

Run the GolfCore tests without Xcode:

```bash
swift test --package-path Packages/GolfCore
```

## Data and attribution

Course data © [OpenStreetMap contributors](https://www.openstreetmap.org/copyright), available under the [Open Database License](https://opendatacommons.org/licenses/odbl/1-0/). Extracts in `data/courses/` are derivative databases and are shared under the ODbL. Satellite imagery is provided by Apple Maps under Apple's terms.

## Licence

GNU Affero General Public License v3.0 or later, with an additional permission under section 7 allowing distribution through the Apple App Store. See [LICENSE](LICENSE).
