# extract

Mac-side extractor. Queries the Overpass API for one golf course, normalizes the OSM features into the app's course JSON schema (`GolfCore.Course`, schema 1), and writes a GPX walk of every hole for Xcode location simulation. Pure Python standard library; use Python 3.10+ (Xcode's bundled 3.9 has a TLS stack that fails against overpass-api.de).

Raw Overpass responses are cached in `.cache/` (ignored by git), so reruns never hit the network. Delete the cache to refresh from OSM.

## List the hole-line candidates

A course area often holds more than one numbered layout (Prenden has an 18 and a 9, both starting at hole 1). The extractor never guesses which is yours; it lists them grouped by name so a human picks:

```bash
python3 tools/extract/extract.py candidates --course-way 4756114
```

## Build the course file and GPX walk

```bash
python3 tools/extract/extract.py build --course-way 4756114 \
  --holes 493700034 493700023 493700010 494080627 494080618 495362018 495362019 495361978 495361968 \
          496005701 496397266 496397257 496397251 498169167 498169163 498169150 498169139 498169131 \
  --out data/courses/prenden.json --gpx data/tracks/prenden-walk.gpx
```

Rules applied:

- One green per hole: the green containing the hole line's last point, else the nearest. A warning is printed if the line does not end inside a green.
- Tees, fairways, bunkers and water attach to the nearest hole line overall, only if that line is one of the listed ones and within 100 m. A feature closer to another layout's hole line is dropped.
- Tee `name` tags are kept (tee colours) for later tee selection.
- The GPX walks each hole first-to-last point at 1.4 m/s, one fix per second, ±2 m jitter, with a 30 s pause on each green and a walk to the next tee.

Data © OpenStreetMap contributors, ODbL. See `data/README.md`.
