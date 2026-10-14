# garmin-car-drive

A Connect IQ **watch app** for the Forerunner 955 / Solar (`fr955`, API 5.2, SDK 9.2.0). It records car drives as a `SPORT_DRIVING` FIT activity, so running and cycling stats and PRs are left alone.

| Drive (recording, no GPS yet) | More | Map | Settings |
|---|---|---|---|
| ![drive](docs/drive.png) | ![more](docs/stats.png) | ![map](docs/map.png) | ![settings](docs/settings.png) |

<sub>Simulator screenshots, statute units. The summary after saving uses the same white style, with one line per value.</sub>

## Use
| Button | Action |
|---|---|
| START | Start the drive. Pressing it again pauses and opens Resume / Save / Discard. Discard asks for confirmation. Save shows the summary. |
| UP / DOWN | Switch pages: Drive → Map → More. The map is skipped until GPS has had its first fix. |
| Hold UP | Idle: settings. Map page: pan/zoom mode (BACK leaves it) |
| BACK | Ignored while a drive is open. If the app is closed anyway, the open drive is saved. |

Screens look like a standard Garmin activity screen: white background, one field per row, with a small title above a big value. The coloured band at the top shows status: green = GPS OK / REC, orange = no GPS, grey = paused, red = off course. The clock and battery are at the bottom.
- **Drive page:** speed, max speed, distance, timer.
- **More page:** average moving speed, stopped time (and number of stops), heading, altitude.
- **No GPS:** START records right away. The timer runs and GPS keeps searching for the whole drive. Time without a fix counts toward neither moving nor stopped time. If GPS drops, the map page shows "waiting for GPS" instead of the map.
- **Map page:** the watch's own map centred on you, your blue breadcrumb, and the purple route when navigation is on, with distance left or distance and time off course.
- **Summary after save:** max speed, average moving speed, distance, total time, moving and stopped time, number of stops (stopped ≥ 10 s), ascent and descent, min and max altitude.
- **Vibration** on start and pause. Leaving the route for more than 5 s triggers a tone and a long vibration.
- **Units** follow the watch's system settings.

## Settings (hold UP on the idle screen)
| Setting | Values | Default |
|---|---|---|
| Navigation | on / off | off |
| Stopped below | 1 / 2 / 3 / 5 / 8 km/h | 2 |
| Off-course alert | 50 / 100 / 200 / 500 m | 100 |

The same settings are also defined for the Garmin Connect phone app. That only works for apps installed from the Connect IQ Store, which is why the watch has its own settings menu.

## Navigation route
The route is bundled into the app (no network). To load a route:
```bash
tools/gpx2route.py my-route.gpx   # writes resources/route/route.json (max 500 points)
./build.sh                        # then sideload build/Car.prg
```
Export the GPX from Garmin Connect (Course → Export GPX) or any route planner. With no route bundled, navigation shows nothing.

## GPX export of a drive
This is already built in: on Garmin Connect web, open the activity → ⚙ → **Export to GPX** (or Export Original for the FIT file). The app doesn't do its own export, because a watch app can't write files you can see over USB, and the only other route off the watch is the phone or network.

## FIT data
Standard session fields include max speed, average speed, distance, ascent and descent. The app also writes three developer fields to the session: `moving_time`, `stopped_time` (seconds) and `stops`. Garmin Connect only shows developer fields for apps installed from the Store. For a sideloaded app they are in the FIT file but not shown in Connect.

## Build (WSL)
```bash
./build.sh       # -> build/Car.prg
./build.sh -t    # include the unit tests (source/Tests.mc)
```
`build.sh` points the Linux compiler at the Windows SDK and devices. The simulator runs on Windows:
`monkeydo.bat build\Car.prg fr955`. In the simulator, set Simulation → Activity Data → ▶ and Settings → Set GPS Quality → Good.

## Install on the watch
1. `./build.sh` (makes `build/Car.prg`).
2. Plug the watch in over USB. On Windows it shows up as a device (MTP) named "Forerunner 955".
3. Copy `Car.prg` into `Internal Storage\GARMIN\APPS\`.
4. Unplug. On the watch: START → scroll the activity/app list → **Car** (add it to favourites from there).

To update, copy over the same file. To remove it, delete it from `GARMIN\APPS`. Settings are kept until then.

## Phase 0 findings (SDK 9.2.0 docs and the fr955 device API)
| # | Question | Finding |
|---|---|---|
| 1 | Sport type | `Activity.SPORT_DRIVING`. The SDK says the sport "is not guaranteed to change device behavior". Whether it counts toward training load or Body Battery **needs a real upload to confirm**. PRs are sport-scoped. |
| FR-4 | Sampling rate | `createSession` has no rate option, so the device default is used. |
| 2 | GPS mode | `CONFIGURATION_GPS` (GPS only, lowest power) is used. SatIQ and multi-band are also available. UltraTrac is not exposed. |
| 3 | Max speed in Connect | Standard FIT session field, so no developer field is needed. |
| 5 | Maps | `MapTrackView` + `MapPolyline` work in a watch app (confirmed in the simulator). In the simulator only one polyline showed at a time, so with nav on the route line is shown in preference to the breadcrumb. Check this on the watch. |
| 6 | Native navigation | No. Courses only expose name, id and `toIntent()`, and the intent exits the app. Off-course detection and alerts are the app's own (distance to the route polyline). No turn-by-turn. |
| 7 | Route import | Bundled JSON resource, built from GPX with `tools/gpx2route.py`. |
| 8 | Map cost | Not measured yet. The breadcrumb gets one point per 6 s moving, capped at 2400 points (about 4 h). The FIT track is always complete. |

## Not possible / skipped
- **Heart rate on/off setting:** there's no API to stop the wrist sensor from recording in a session. Turn wrist HR off on the watch itself if you need to.
- **North-up vs heading-up:** controlled by the watch's map settings; there's no API for it.
- Phase 3 (accelerometer events, grade) has not been started.

---

# Sail (data field)

Sailing values for a **built-in** activity. Everything else comes from the watch itself, so it looks and behaves like any native activity: the map, breadcrumb, compass/heading, Save Location, navigating to a saved location, the screen theme, and recording.

| Slot size | Shows |
|---|---|
| Small (1 value) | SOG kn |
| Half screen (2 values) | SOG kn, MAX kn |
| Full screen | SOG kn, MAX kn, DIST nm. While navigating to a point: SOG, MAX, **VMG kn**, **DTW nm** |

- **SOG**: speed over ground from GPS, in knots.
- **VMG**: speed toward the point you're navigating to (negative = moving away).
- **DTW**: distance to that point, in nautical miles.

Colours follow the activity's background (black or white).

## Set up on the watch (one time)
The Forerunner has no Sail activity, so create one:
1. Build and copy: `./build.sh sail`, then copy `build/Sail.prg` to `GARMIN\APPS\` on the watch.
2. On the watch: START → **Add** → custom activity (or copy an existing GPS activity) → name it "Sail". Pick a non-sport type such as Other if the watch offers one, so sailing doesn't affect run/bike stats. In Garmin Connect you can also change a saved activity's type to Sailing.
3. In that activity's settings → Data Screens: add a full-screen layout and set its field to **Connect IQ → Sail**. Also turn on the **Map** and **Compass** screens, and add native fields if you want them (Heading, Bearing).

## Use on the water
- **Save point:** during the activity, hold MENU (UP) → **Save Location**.
- **Head to point:** hold MENU → **Navigation** → **Saved Locations** → pick one. The native pointer, distance and ETA appear, and the Sail field switches to VMG/DTW.
- **Track:** the native map shows the breadcrumb, and Navigation can also follow courses.

Limits: an activity can hold at most 2 Connect IQ fields. Units are fixed at knots and nm. The sport type is whatever the custom activity records.

Tests: `./build.sh sail -t`, then run it in the simulator with `monkeydo.bat build\Sail.prg fr955 /t`.
