import Toybox.Activity;
import Toybox.ActivityRecording;
import Toybox.Application;
import Toybox.Attention;
import Toybox.FitContributor;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.Position;
import Toybox.WatchUi;

const STOP_MIN_S = 10;  // a stop counts once stopped this long (filters stop-and-go traffic)
const TRAIL_S = 6;      // breadcrumb point every N moving seconds
const TRAIL_MAX = 2400; // shortcut: map breadcrumb stops growing after ~4 h moving (FIT track stays complete); decimate if device memory allows less
const OFF_ALERT_S = 5;  // seconds off course before alerting
const EARTH_R = 6371000.0;

// Recording state and derived stats, shared by all pages
class Drive {

    var gps as Position.Info?;
    var seenFix as Boolean = false;
    var session as ActivityRecording.Session?;
    var summary as Dictionary?; // stats of the last saved drive

    var stopKmh as Number = 2;
    var stopMps as Float = 0.56;
    var offCourseM as Number = 100;
    var navOn as Boolean = false;

    var moving as Number = 0;
    var stopped as Number = 0;
    var stopRun as Number = 0;
    var stops as Number = 0;
    var altMin as Float?;
    var altMax as Float?;
    var fields as Array<FitContributor.Field> = [];

    var trail as WatchUi.MapPolyline?;
    var trailN as Number = 0;
    var mapVer as Number = 0; // bumped when a map line changes

    var routeLine as WatchUi.MapPolyline?;
    var rLat as Array<Float>?;
    var rLon as Array<Float>?;
    var rCum as Array<Float>?;
    var offM as Float?;  // distance from the route
    var leftM as Float?; // route distance remaining
    var offS as Number = 0;

    function initialize() {
        loadSettings();
    }

    function loadSettings() as Void {
        stopKmh = prop("stopKmh", 2) as Number;
        stopMps = stopKmh / 3.6;
        offCourseM = prop("offCourseM", 100) as Number;
        navOn = prop("navOn", false) as Boolean;
        if (navOn && rLat == null) {
            loadRoute();
        }
        mapVer++;
    }

    function loadRoute() as Void {
        var pts = WatchUi.loadResource(Rez.JsonData.Route) as Array<Array<Numeric>>;
        var n = pts.size();
        if (n < 2) {
            return;
        }
        rLat = new Array<Float>[n];
        rLon = new Array<Float>[n];
        rCum = new Array<Float>[n];
        routeLine = new WatchUi.MapPolyline();
        routeLine.setColor(Graphics.COLOR_PURPLE);
        routeLine.setWidth(4);
        for (var i = 0; i < n; i++) {
            rLat[i] = Math.toRadians(pts[i][0]).toFloat();
            rLon[i] = Math.toRadians(pts[i][1]).toFloat();
            rCum[i] = i == 0 ? 0.0 : rCum[i - 1] + segLen(rLat[i - 1], rLon[i - 1], rLat[i], rLon[i]);
            routeLine.addLocation(new Position.Location({:latitude => pts[i][0], :longitude => pts[i][1], :format => :degrees}));
        }
    }

    function speed() as Float {
        return gps != null && gps.speed != null ? gps.speed : 0.0;
    }

    function hasFix() as Boolean {
        return gps != null && gps.position != null && gps.accuracy != null && gps.accuracy >= Position.QUALITY_USABLE;
    }

    function isRecording() as Boolean {
        return session != null && session.isRecording();
    }

    function isOffCourse() as Boolean {
        return navOn && offS >= OFF_ALERT_S;
    }

    function start() as Void {
        if (session == null) {
            session = ActivityRecording.createSession({
                :name => "Car",
                :sport => Activity.SPORT_DRIVING,
                :subSport => Activity.SUB_SPORT_GENERIC
            });
            var opts = {:mesgType => FitContributor.MESG_TYPE_SESSION, :units => "s"};
            fields = [
                session.createField("moving_time", 0, FitContributor.DATA_TYPE_UINT32, opts),
                session.createField("stopped_time", 1, FitContributor.DATA_TYPE_UINT32, opts),
                session.createField("stops", 2, FitContributor.DATA_TYPE_UINT16, {:mesgType => FitContributor.MESG_TYPE_SESSION})
            ];
            moving = 0;
            stopped = 0;
            stopRun = 0;
            stops = 0;
            altMin = null;
            altMax = null;
            offS = 0;
            trail = new WatchUi.MapPolyline();
            trail.setColor(Graphics.COLOR_BLUE);
            trail.setWidth(3);
            trailN = 0;
            mapVer++;
        }
        session.start();
        buzz(200);
    }

    function pause() as Void {
        if (session == null) {
            return;
        }
        session.stop();
        buzz(200);
    }

    function save() as Void {
        if (session != null) {
            summary = stats();
            session.stop();
            session.save();
            session = null;
        }
    }

    function discard() as Void {
        if (session != null) {
            session.stop();
            session.discard();
            session = null;
        }
    }

    // Called once per second by the app timer
    function tick() as Void {
        if (!isRecording()) {
            return;
        }
        var spd = speed();
        if (!hasFix()) {
            // no GPS yet: the timer still runs, but the time is neither moving nor stopped
        } else if (spd >= stopMps) {
            moving++;
            stopRun = 0;
        } else {
            stopped++;
            stopRun++;
            if (stopRun == STOP_MIN_S && moving > 0) {
                stops++;
            }
        }
        fields[0].setData(moving);
        fields[1].setData(stopped);
        fields[2].setData(stops);

        var info = Activity.getActivityInfo();
        var alt = info != null ? info.altitude : null;
        if (alt != null) {
            altMin = altMin == null || alt < altMin ? alt : altMin;
            altMax = altMax == null || alt > altMax ? alt : altMax;
        }

        if (!hasFix()) {
            return;
        }
        var loc = gps.position;
        if (spd >= stopMps && moving % TRAIL_S == 0 && trailN < TRAIL_MAX) {
            trail.addLocation(loc);
            trailN++;
            mapVer++;
        }
        if (navOn && rLat != null) {
            var p = loc.toRadians();
            var fix = routeFix(p[0].toFloat(), p[1].toFloat(), rLat, rLon, rCum);
            offM = fix[0];
            leftM = fix[1];
            if (offM > offCourseM) {
                offS++;
                if (offS == OFF_ALERT_S) {
                    if (Attention has :playTone) {
                        Attention.playTone(Attention.TONE_ALERT_HI);
                    }
                    buzz(1000);
                }
            } else {
                offS = 0;
            }
        }
    }

    // Everything the screens show, null where there's no data yet (no GPS, no session)
    function stats() as Dictionary {
        var s = {
            :speed => hasFix() ? speed() : null,
            :heading => null,
            :moving => moving,
            :stopped => stopped,
            :stops => stops,
            :altMin => altMin,
            :altMax => altMax,
            :timer => 0,
            :elapsed => 0
        };
        if (hasFix() && gps.heading != null && speed() >= stopMps) {
            s[:heading] = (Math.toDegrees(gps.heading).toNumber() + 360) % 360;
        }
        var i = Activity.getActivityInfo();
        if (i != null) {
            s[:max] = i.maxSpeed;
            s[:dist] = i.elapsedDistance;
            s[:alt] = i.altitude;
            s[:ascent] = i.totalAscent;
            s[:descent] = i.totalDescent;
            s[:timer] = i.timerTime != null ? i.timerTime / 1000 : 0;
            s[:elapsed] = i.elapsedTime != null ? i.elapsedTime / 1000 : 0;
        }
        return s;
    }

    function buzz(ms as Number) as Void {
        if (Attention has :vibrate) {
            Attention.vibrate([new Attention.VibeProfile(75, ms)]);
        }
    }
}

// Equirectangular distance in metres between two points in radians (fine at route-segment scale)
function segLen(lat1 as Float, lon1 as Float, lat2 as Float, lon2 as Float) as Float {
    var x = (lon2 - lon1) * Math.cos((lat1 + lat2) / 2);
    var y = lat2 - lat1;
    return (EARTH_R * Math.sqrt(x * x + y * y)).toFloat();
}

// [distance to route, route distance remaining] in metres, from the nearest segment
function routeFix(lat as Float, lon as Float, rLat as Array<Float>, rLon as Array<Float>, rCum as Array<Float>) as [Float, Float] {
    var k = Math.cos(lat) * EARTH_R;
    var best = 1.0e12;
    var bi = 0;
    var bt = 0.0;
    for (var i = 0; i < rLat.size() - 1; i++) {
        // segment endpoints in metres, relative to the current position
        var ax = (rLon[i] - lon) * k;
        var ay = (rLat[i] - lat) * EARTH_R;
        var dx = (rLon[i + 1] - lon) * k - ax;
        var dy = (rLat[i + 1] - lat) * EARTH_R - ay;
        var l2 = dx * dx + dy * dy;
        var t = l2 > 0 ? -(ax * dx + ay * dy) / l2 : 0.0;
        t = t < 0 ? 0.0 : t > 1 ? 1.0 : t;
        var px = ax + t * dx;
        var py = ay + t * dy;
        var d2 = px * px + py * py;
        if (d2 < best) {
            best = d2;
            bi = i;
            bt = t;
        }
    }
    var done = rCum[bi] + bt * (rCum[bi + 1] - rCum[bi]);
    return [Math.sqrt(best).toFloat(), (rCum[rCum.size() - 1] - done).toFloat()];
}

function prop(key as String, dflt as PropertyValueType) as PropertyValueType {
    var v = Properties.getValue(key);
    return v != null ? v : dflt;
}
