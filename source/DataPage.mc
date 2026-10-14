import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;

// Standard activity-style data screen: status band on top, one field per row (small title, big value)
// kind: :drive (page 1), :more (page 3), :summary (after save)
class DataPage extends WatchUi.View {

    var drive as Drive;
    var kind as Symbol;

    function initialize(d as Drive, k as Symbol) {
        View.initialize();
        drive = d;
        kind = k;
    }

    function onUpdate(dc as Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE);
        dc.clear();

        // Status band
        var band = "SAVED";
        var color = Graphics.COLOR_DK_GRAY;
        if (kind != :summary) {
            var fix = drive.hasFix();
            band = drive.session == null ? (fix ? "GPS OK" : "GPS...") : (drive.isRecording() ? "REC" : "PAUSED") + (fix ? "" : " GPS...");
            color = drive.isOffCourse() ? Graphics.COLOR_RED : !fix ? Graphics.COLOR_ORANGE
                : drive.session != null && !drive.isRecording() ? Graphics.COLOR_DK_GRAY : Graphics.COLOR_DK_GREEN;
            if (drive.isOffCourse()) {
                band = "OFF COURSE";
            }
        }
        dc.setColor(color, color);
        dc.fillRectangle(0, 0, w, 36);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, 24, Graphics.FONT_XTINY, band, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Bottom: clock + battery
        var t = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h - 14, Graphics.FONT_XTINY,
            t.hour.format("%02d") + ":" + t.min.format("%02d") + "  " + System.getSystemStats().battery.format("%d") + "%",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        if (kind == :drive && drive.session == null) {
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
            dc.drawText(w / 2, h / 2 - 10, Graphics.FONT_MEDIUM, "Press START", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(w / 2, h / 2 + 24, Graphics.FONT_XTINY, "Hold UP: settings", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            return;
        }

        var s = kind == :summary && drive.summary != null ? drive.summary : drive.stats();
        drawRows(dc, rows(s), 36, h - 30);
    }

    function rows(s as Dictionary) as Array<[String, String]> {
        var moving = s[:moving] as Number;
        var dist = s[:dist] as Float?;
        var avg = fmtSpeed(dist != null && moving > 0 ? dist / moving : null) + speedUnit();
        var stopped = fmtTime(s[:stopped] as Number) + " (" + s[:stops] + ")";
        if (kind == :drive) {
            return [
                ["SPEED", fmtSpeed(s[:speed] as Float?) + speedUnit()],
                ["MAX SPEED", fmtSpeed(s[:max] as Float?) + speedUnit()],
                ["DISTANCE", fmtDist(dist)],
                ["TIMER", fmtTime(s[:timer] as Number)]
            ];
        }
        if (kind == :more) {
            var hdg = s[:heading] as Number?;
            return [
                ["AVG MOVING", avg],
                ["STOPPED (STOPS)", stopped],
                ["HEADING", hdg != null ? cardinal(hdg) + " " + hdg : "--"],
                ["ALTITUDE", fmtAlt(s[:alt] as Numeric?)]
            ];
        }
        return [
            ["Max speed", fmtSpeed(s[:max] as Float?) + speedUnit()],
            ["Avg moving", avg],
            ["Distance", fmtDist(dist)],
            ["Total time", fmtTime(s[:elapsed] as Number)],
            ["Moving", fmtTime(moving)],
            ["Stopped", stopped],
            ["Ascent", fmtAlt(s[:ascent] as Numeric?) + " / " + fmtAlt(s[:descent] as Numeric?)],
            ["Altitude", fmtAlt(s[:altMin] as Numeric?) + " - " + fmtAlt(s[:altMax] as Numeric?)]
        ];
    }
}

// Rows between y0 and y1 separated by lines. Up to 4 rows: title above a big value; more: "title value" on one line.
function drawRows(dc as Dc, rows as Array<[String, String]>, y0 as Number, y1 as Number) as Void {
    var w = dc.getWidth();
    var cx = w / 2;
    var n = rows.size();
    var rh = (y1 - y0) / n;
    var big = dc.getFontHeight(Graphics.FONT_LARGE) <= rh - 16 ? Graphics.FONT_LARGE : Graphics.FONT_MEDIUM;
    for (var i = 0; i < n; i++) {
        var y = y0 + i * rh;
        if (i > 0) {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawLine(0, y, w, y);
        }
        if (n <= 4) {
            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, y + 9, Graphics.FONT_XTINY, rows[i][0], Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, y + 16 + (rh - 16) / 2, big, rows[i][1], Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        } else {
            var yc = y + rh / 2;
            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx - 4, yc, Graphics.FONT_XTINY, rows[i][0], Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx + 4, yc, Graphics.FONT_XTINY, rows[i][1], Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }
}
