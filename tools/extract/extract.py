#!/usr/bin/env python3
"""Extract one golf course from OpenStreetMap into Ace Golf's course JSON and a GPX walk.

Pure standard library. Two commands:

  candidates --course-way <id>
      Fetch all golf features around the course and list the golf=hole ways with ref, par,
      name and centroid, grouped by name, so a human can pick the hole-line way ids for the
      layout being played.

  build --course-way <id> --holes <id> [<id> ...] --out <course.json> [--gpx <walk.gpx>]
      Build the normalized course file from an explicit list of hole-line way ids, and a GPX
      track that walks every hole tee to green for Xcode location simulation.

Raw Overpass responses are cached under tools/extract/.cache so reruns never hit the network.
Data (c) OpenStreetMap contributors, ODbL.
"""
import argparse
import hashlib
import json
import math
import os
import random
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from datetime import datetime, timedelta, timezone

MIRRORS = [
    "https://overpass-api.de/api/interpreter",
    "https://overpass.kumi.systems/api/interpreter",
    "https://lz4.overpass-api.de/api/interpreter",
    "https://overpass.private.coffee/api/interpreter",
]
USER_AGENT = "ace-golf-extract/0.1 (+https://github.com/positonic/ace-golf)"
CACHE_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), ".cache")
SCHEMA = 1
ASSIGN_MAX_M = 100.0
EARTH_R = 6371008.8


# ----------------------------------------------------------------------------- geometry

def haversine(a, b):
    """Metres between two (lon, lat) points."""
    lon1, lat1, lon2, lat2 = map(math.radians, (a[0], a[1], b[0], b[1]))
    dlat, dlon = lat2 - lat1, lon2 - lon1
    h = math.sin(dlat / 2) ** 2 + math.cos(lat1) * math.cos(lat2) * math.sin(dlon / 2) ** 2
    return 2 * EARTH_R * math.asin(math.sqrt(h))


def local_xy(origin):
    """Equirectangular projection to metres around origin (lon, lat). Fine at course scale."""
    lat0 = math.radians(origin[1])
    kx = EARTH_R * math.cos(lat0) * math.pi / 180
    ky = EARTH_R * math.pi / 180
    def to_xy(p):
        return ((p[0] - origin[0]) * kx, (p[1] - origin[1]) * ky)
    return to_xy


def point_segment_distance(p, a, b):
    px, py = p; ax, ay = a; bx, by = b
    dx, dy = bx - ax, by - ay
    if dx == dy == 0:
        return math.hypot(px - ax, py - ay)
    t = max(0.0, min(1.0, ((px - ax) * dx + (py - ay) * dy) / (dx * dx + dy * dy)))
    return math.hypot(px - (ax + t * dx), py - (ay + t * dy))


def point_line_distance_m(p, line, to_xy):
    pxy = to_xy(p)
    xy = [to_xy(q) for q in line]
    return min(point_segment_distance(pxy, xy[i], xy[i + 1]) for i in range(len(xy) - 1))


def point_in_ring(p, ring):
    x, y = p
    inside = False
    n = len(ring)
    for i in range(n):
        x1, y1 = ring[i]
        x2, y2 = ring[(i + 1) % n]
        if (y1 > y) != (y2 > y):
            xi = (x2 - x1) * (y - y1) / (y2 - y1) + x1
            if x < xi:
                inside = not inside
    return inside


def centroid(ring):
    n = len(ring)
    return (sum(p[0] for p in ring) / n, sum(p[1] for p in ring) / n)


def bearing(a, b):
    lon1, lat1, lon2, lat2 = map(math.radians, (a[0], a[1], b[0], b[1]))
    y = math.sin(lon2 - lon1) * math.cos(lat2)
    x = math.cos(lat1) * math.sin(lat2) - math.sin(lat1) * math.cos(lat2) * math.cos(lon2 - lon1)
    return (math.degrees(math.atan2(y, x)) + 360) % 360


# ----------------------------------------------------------------------------- overpass

def overpass(query):
    os.makedirs(CACHE_DIR, exist_ok=True)
    key = hashlib.sha1(query.encode()).hexdigest()[:16]
    path = os.path.join(CACHE_DIR, f"{key}.json")
    if os.path.exists(path):
        with open(path) as f:
            return json.load(f)
    data = urllib.parse.urlencode({"data": query}).encode()
    delay = 2
    for attempt in range(8):
        url = MIRRORS[attempt % len(MIRRORS)]
        req = urllib.request.Request(url, data=data, headers={"User-Agent": USER_AGENT})
        try:
            with urllib.request.urlopen(req, timeout=90) as r:
                body = r.read()
            result = json.loads(body)
            if result.get("remark") and "runtime error" in result["remark"]:
                raise RuntimeError(result["remark"])
            with open(path, "w") as f:
                json.dump(result, f)
            return result
        except Exception as e:  # URLError, HTTPError, socket.timeout, JSON errors, runtime remarks
            print(f"  overpass {url}: {e}; retrying in {delay}s", file=sys.stderr)
            time.sleep(delay)
            delay = min(delay * 2, 60)
    raise SystemExit("Overpass: all mirrors failed")


def fetch_course_area(course_way):
    """Fetch the course polygon and every golf feature inside its bounding box plus a margin."""
    course = overpass(f"[out:json][timeout:60];way({course_way});out geom;")
    ways = [e for e in course["elements"] if e["type"] == "way"]
    if not ways:
        raise SystemExit(f"way {course_way} not found")
    ring = [(n["lon"], n["lat"]) for n in ways[0]["geometry"]]
    lons = [p[0] for p in ring]; lats = [p[1] for p in ring]
    m = 0.003  # ~300 m margin
    bbox = f"{min(lats)-m},{min(lons)-m},{max(lats)+m},{max(lons)+m}"
    q = f"""[out:json][timeout:90];
(
  way[golf]({bbox});
  relation[golf]({bbox});
  way[natural=water]({bbox});
  relation[natural=water]({bbox});
);
out geom;"""
    feats = overpass(q)
    return ways[0], ring, feats["elements"]


# ----------------------------------------------------------------------------- features

def rings_of(el):
    """Outer rings of a way or multipolygon relation, as lists of (lon, lat), closing point dropped."""
    if el["type"] == "way":
        g = el.get("geometry")
        if not g:
            return []
        ring = [(n["lon"], n["lat"]) for n in g]
        if len(ring) > 1 and ring[0] == ring[-1]:
            ring = ring[:-1]
        return [ring]
    rings = []
    for mem in el.get("members", []):
        if mem.get("role") == "outer" and mem.get("geometry"):
            ring = [(n["lon"], n["lat"]) for n in mem["geometry"]]
            if len(ring) > 1 and ring[0] == ring[-1]:
                ring = ring[:-1]
            rings.append(ring)
    return rings


def line_of(el):
    return [(n["lon"], n["lat"]) for n in el.get("geometry", [])]


def kind(el):
    t = el.get("tags", {})
    g = t.get("golf")
    if g in ("hole", "green", "tee", "fairway", "bunker"):
        return g
    if g in ("water_hazard", "lateral_water_hazard") or t.get("natural") == "water":
        return "water"
    return None


# ----------------------------------------------------------------------------- commands

def cmd_candidates(args):
    _, course_ring, elements = fetch_course_area(args.course_way)
    holes = [e for e in elements if e["type"] == "way" and e.get("tags", {}).get("golf") == "hole"]
    groups = {}
    for h in holes:
        t = h["tags"]
        line = line_of(h)
        c = centroid(line) if line else (0, 0)
        inside = point_in_ring(c, course_ring)
        groups.setdefault(t.get("name") or "(no name)", []).append((int(t.get("ref") or 0), h["id"], t.get("par"), inside, len(line)))
    print(f"course way {args.course_way}: {len(holes)} golf=hole ways in the area\n")
    for name, rows in sorted(groups.items()):
        pars = [int(r[2]) for r in rows if r[2]]
        print(f"group '{name}': {len(rows)} holes, par total {sum(pars) if len(pars)==len(rows) else 'incomplete'}")
        for ref, wid, par, inside, npts in sorted(rows):
            print(f"  ref {ref:>2}  way {wid}  par {par or '-'}  pts {npts}  {'inside' if inside else 'OUTSIDE'} course polygon")
        print(f"  ids: {' '.join(str(r[1]) for r in sorted(rows))}\n")


def cmd_build(args):
    course_el, course_ring, elements = fetch_course_area(args.course_way)
    to_xy = local_xy(centroid(course_ring))
    wanted = set(args.holes)

    all_hole_lines = {e["id"]: line_of(e) for e in elements if e["type"] == "way" and e.get("tags", {}).get("golf") == "hole"}
    missing = wanted - set(all_hole_lines)
    if missing:
        raise SystemExit(f"hole ways not found in area: {sorted(missing)}")

    def nearest_hole(p):
        best = (None, float("inf"))
        for hid, line in all_hole_lines.items():
            if len(line) < 2:
                continue
            d = point_line_distance_m(p, line, to_xy)
            if d < best[1]:
                best = (hid, d)
        return best

    holes = {}
    for e in elements:
        if e["type"] != "way" or e["id"] not in wanted:
            continue
        t = e["tags"]
        number = int(t.get("ref") or 0)
        if number == 0:
            print(f"warning: hole way {e['id']} has no numeric ref; skipped", file=sys.stderr)
            continue
        holes[number] = {
            "number": number,
            "par": int(t["par"]) if t.get("par", "").isdigit() else None,
            "handicap": int(t["handicap"]) if t.get("handicap", "").isdigit() else None,
            "osmWay": e["id"],
            "line": all_hole_lines[e["id"]],
            "green": None, "tees": [], "fairways": [], "bunkers": [], "water": [],
        }
    by_way = {h["osmWay"]: h for h in holes.values()}

    # Greens: one per hole, the green containing (or nearest to) the hole line's last point.
    greens = [(e, r) for e in elements if kind(e) == "green" for r in rings_of(e)]
    for h in holes.values():
        end = h["line"][-1]
        best = None
        for e, ring in greens:
            if point_in_ring(end, ring):
                best = (0.0, ring); break
            d = haversine(end, centroid(ring))
            if best is None or d < best[0]:
                best = (d, ring)
        if best is None:
            print(f"warning: hole {h['number']}: no green found", file=sys.stderr)
            continue
        if best[0] > 0:
            print(f"warning: hole {h['number']}: line does not end inside a green (nearest green {best[0]:.0f} m away)", file=sys.stderr)
        h["green"] = best[1]

    # Everything else: attach to the nearest hole line overall, only if that line is one of ours
    # and within ASSIGN_MAX_M. A feature closer to another layout's hole line is dropped.
    for e in elements:
        k = kind(e)
        if k in (None, "hole", "green"):
            continue
        for ring in rings_of(e):
            if len(ring) < 3:
                continue
            c = centroid(ring)
            if not point_in_ring(c, course_ring):
                continue
            hid, d = nearest_hole(c)
            if hid not in by_way or d > ASSIGN_MAX_M:
                continue
            h = by_way[hid]
            if k == "tee":
                h["tees"].append({"name": e.get("tags", {}).get("name"), "polygon": ring})
            else:
                h[{"fairway": "fairways", "bunker": "bunkers", "water": "water"}[k]].append(ring)

    # Sanity: does each line start inside one of its tees?
    for h in holes.values():
        start = h["line"][0]
        if h["tees"] and not any(point_in_ring(start, t["polygon"]) for t in h["tees"]):
            near = min(haversine(start, centroid(t["polygon"])) for t in h["tees"])
            print(f"note: hole {h['number']}: line does not start inside a tee (nearest tee {near:.0f} m)", file=sys.stderr)
        if not h["tees"]:
            print(f"note: hole {h['number']}: no tees attached", file=sys.stderr)

    def pt(p): return [round(p[0], 7), round(p[1], 7)]
    def ring_json(r): return [pt(p) for p in r]

    out = {
        "schema": SCHEMA,
        "id": f"osm-way-{args.course_way}",
        "name": course_el.get("tags", {}).get("name", f"way {args.course_way}"),
        "osm": {"courseWay": args.course_way, "holeWays": sorted(wanted)},
        "polygon": ring_json(course_ring),
        "holes": [],
    }
    for n in sorted(holes):
        h = holes[n]
        if h["green"] is None:
            raise SystemExit(f"hole {n} has no green; fix the data or drop the hole")
        out["holes"].append({
            "number": n, "par": h["par"], "handicap": h["handicap"],
            "line": ring_json(h["line"]),
            "green": ring_json(h["green"]),
            "tees": [{"name": t["name"], "polygon": ring_json(t["polygon"])} for t in h["tees"]],
            "fairways": [ring_json(r) for r in h["fairways"]],
            "bunkers": [ring_json(r) for r in h["bunkers"]],
            "water": [ring_json(r) for r in h["water"]],
        })
    os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
    with open(args.out, "w") as f:
        json.dump(out, f, separators=(",", ":"))
    print(f"wrote {args.out}: {len(out['holes'])} holes, "
          f"{sum(len(h['tees']) for h in out['holes'])} tees, "
          f"{sum(len(h['fairways']) for h in out['holes'])} fairways, "
          f"{sum(len(h['bunkers']) for h in out['holes'])} bunkers, "
          f"{sum(len(h['water']) for h in out['holes'])} water")
    for h in out["holes"]:
        b = bearing(tuple(h["line"][0]), tuple(h["line"][-1]))
        length = sum(haversine(tuple(h["line"][i]), tuple(h["line"][i+1])) for i in range(len(h["line"])-1))
        print(f"  hole {h['number']:>2} par {h['par'] or '-'} {length:4.0f} m bearing {b:3.0f} "
              f"tees {len(h['tees'])} fw {len(h['fairways'])} bk {len(h['bunkers'])} wt {len(h['water'])}")

    if args.gpx:
        write_gpx(args.gpx, out, args.seed)


def write_gpx(path, course, seed):
    """Walk every hole first-to-last point at 1.4 m/s, one fix per second, +-2 m jitter,
    and walk green to next tee between holes."""
    rnd = random.Random(seed)
    t = datetime(2026, 10, 23, 8, 0, 0, tzinfo=timezone.utc)
    pts = []
    def walk(a, b):
        nonlocal t
        d = haversine(a, b)
        steps = max(1, int(d / 1.4))
        for i in range(steps + 1):
            f = i / steps
            lon = a[0] + (b[0] - a[0]) * f + rnd.uniform(-2, 2) / (111320 * math.cos(math.radians(a[1])))
            lat = a[1] + (b[1] - a[1]) * f + rnd.uniform(-2, 2) / 110540
            pts.append((lon, lat, t))
            t += timedelta(seconds=1)
    prev_end = None
    for h in course["holes"]:
        line = [tuple(p) for p in h["line"]]
        if prev_end is not None:
            walk(prev_end, line[0])
        for i in range(len(line) - 1):
            walk(line[i], line[i + 1])
        prev_end = line[-1]
        t += timedelta(seconds=30)  # putting out
    os.makedirs(os.path.dirname(os.path.abspath(path)), exist_ok=True)
    with open(path, "w") as f:
        f.write('<?xml version="1.0" encoding="UTF-8"?>\n')
        f.write('<gpx version="1.1" creator="ace-golf extract" xmlns="http://www.topografix.com/GPX/1/1">\n')
        f.write(f'<trk><name>{course["name"]} walk</name><trkseg>\n')
        for lon, lat, ts in pts:
            f.write(f'<trkpt lat="{lat:.7f}" lon="{lon:.7f}"><time>{ts.strftime("%Y-%m-%dT%H:%M:%SZ")}</time></trkpt>\n')
        f.write('</trkseg></trk></gpx>\n')
    print(f"wrote {path}: {len(pts)} points, {(pts[-1][2]-pts[0][2]).seconds//60} min")


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = p.add_subparsers(dest="cmd", required=True)
    c = sub.add_parser("candidates"); c.add_argument("--course-way", type=int, required=True); c.set_defaults(fn=cmd_candidates)
    b = sub.add_parser("build")
    b.add_argument("--course-way", type=int, required=True)
    b.add_argument("--holes", type=int, nargs="+", required=True)
    b.add_argument("--out", required=True)
    b.add_argument("--gpx")
    b.add_argument("--seed", type=int, default=1)
    b.set_defaults(fn=cmd_build)
    args = p.parse_args()
    args.fn(args)


if __name__ == "__main__":
    main()
