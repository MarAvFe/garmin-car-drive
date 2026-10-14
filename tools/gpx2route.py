#!/usr/bin/env python3
"""Convert a GPX track/route into resources/route/route.json (the navigation route). Rebuild the app afterwards.

Usage: tools/gpx2route.py drive.gpx
"""
import json, math, os, sys
import xml.etree.ElementTree as ET

MAX_PTS = 500  # the watch scans every segment once per second

pts = [(float(e.get('lat')), float(e.get('lon')))
       for e in ET.parse(sys.argv[1]).iter() if e.tag.split('}')[-1] in ('trkpt', 'rtept')]
if len(pts) < 2:
    sys.exit('need at least 2 trkpt/rtept points')
# shortcut: uniform decimation can cut corners on long twisty routes; switch to Douglas-Peucker if it does
keep = pts[::math.ceil(len(pts) / MAX_PTS)]
if keep[-1] != pts[-1]:
    keep.append(pts[-1])
out = os.path.join(os.path.dirname(__file__), '..', 'resources', 'route', 'route.json')
json.dump([[round(a, 6), round(b, 6)] for a, b in keep], open(out, 'w'))
print(f'{len(pts)} -> {len(keep)} points written to {os.path.normpath(out)}')
