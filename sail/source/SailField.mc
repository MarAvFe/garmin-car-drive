import Toybox.Activity;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.WatchUi;

const KN = 1.943844; // m/s -> knots
const NM = 1852.0;   // metres per nautical mile

// Sailing values in knots / nautical miles for a native activity. Shows 1, 2 or 4 values
// depending on the slot size the activity layout gives it; colours follow the activity theme.
class SailField extends WatchUi.DataField {

    var sog as Float?;
    var maxSog as Float?;
    var dist as Float?;
    var vmg as Float?; // velocity made good toward the point being navigated to
    var dtw as Float?; // distance to that point

    function initialize() {
        DataField.initialize();
    }

    function compute(info as Activity.Info) as Void {
        sog = info.currentSpeed;
        maxSog = info.maxSpeed;
        dist = info.elapsedDistance;
        dtw = info.distanceToDestination;
        vmg = null;
        if (sog != null && info.track != null && info.bearing != null && dtw != null) {
            vmg = velocityMadeGood(sog, info.track, info.bearing);
        }
    }

    function onUpdate(dc as Dc) as Void {
        var bg = getBackgroundColor();
        var fg = bg == Graphics.COLOR_BLACK ? Graphics.COLOR_WHITE : Graphics.COLOR_BLACK;
        dc.setColor(bg, bg);
        dc.clear();

        var nav = dtw != null;
        var cells = [
            ["SOG kn", fmt(sog, KN)],
            ["MAX kn", fmt(maxSog, KN)],
            nav ? ["VMG kn", fmt(vmg, KN)] : ["DIST nm", fmt(dist, 1 / NM)],
            nav ? ["DTW nm", fmt(dtw, 1 / NM)] : ["", ""]
        ];
        var w = dc.getWidth();
        var h = dc.getHeight();
        var cols = w >= 180 ? 2 : 1;
        var rows = h >= 180 ? 2 : 1;
        if (!nav && cols * rows == 4) {
            rows = 1; cols = 3; // 3 values only: one row
        }
        var cw = w / cols;
        var ch = h / rows;
        for (var i = 0; i < cols * rows; i++) {
            var x = (i % cols) * cw + cw / 2;
            var y = (i / cols) * ch + ch / 2;
            dc.setColor(fg, Graphics.COLOR_TRANSPARENT);
            dc.drawText(x, y - ch / 4, Graphics.FONT_XTINY, cells[i][0], Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            dc.drawText(x, y + ch / 8, ch >= 90 ? Graphics.FONT_NUMBER_MEDIUM : Graphics.FONT_NUMBER_MILD, cells[i][1], Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }
}

function fmt(v as Float?, k as Float) as String {
    return v == null ? "--" : (v * k).format("%.1f");
}

// Component of speed along the bearing to the target (negative = moving away). Angles in radians.
function velocityMadeGood(speed as Float, track as Float, bearing as Float) as Float {
    return (speed * Math.cos(bearing - track)).toFloat();
}
