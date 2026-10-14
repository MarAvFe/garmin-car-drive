import Toybox.Activity;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;

// Page 1: live driving fields
class CarView extends WatchUi.View {

    var drive as Drive;

    function initialize(d as Drive) {
        View.initialize();
        drive = d;
    }

    function onUpdate(dc as Dc) as Void {
        var cx = dc.getWidth() / 2;
        var info = Activity.getActivityInfo();

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        // Top: clock + battery
        var t = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 8, Graphics.FONT_XTINY,
            t.hour.format("%02d") + ":" + t.min.format("%02d") + "  " + System.getSystemStats().battery.format("%d") + "%",
            Graphics.TEXT_JUSTIFY_CENTER);

        // Status line
        var status = "GPS OK";
        var color = Graphics.COLOR_GREEN;
        if (drive.isOffCourse()) {
            status = "OFF COURSE";
            color = Graphics.COLOR_RED;
        } else if (drive.session != null) {
            status = drive.isRecording() ? "REC" : "PAUSED";
            color = drive.isRecording() ? Graphics.COLOR_RED : Graphics.COLOR_YELLOW;
        }
        if (!drive.hasFix()) {
            status = drive.session != null ? status + " GPS..." : "GPS...";
            color = drive.isRecording() ? Graphics.COLOR_RED : Graphics.COLOR_YELLOW;
        }
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 30, Graphics.FONT_TINY, status, Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        if (drive.session == null) {
            dc.drawText(cx, 130, Graphics.FONT_MEDIUM, "Press START", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, 170, Graphics.FONT_XTINY, "Hold UP: settings", Graphics.TEXT_JUSTIFY_CENTER);
            return;
        }

        // Current speed (primary) and max speed
        var spd = drive.speed();
        dc.drawText(cx, 52, Graphics.FONT_NUMBER_THAI_HOT, fmtSpeed(spd), Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(Graphics.COLOR_ORANGE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 140, Graphics.FONT_MEDIUM, "MAX " + fmtSpeed(info.maxSpeed) + speedUnit(), Graphics.TEXT_JUSTIFY_CENTER);

        // Distance | timer time
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx - 6, 172, Graphics.FONT_SMALL, fmtDist(info.elapsedDistance), Graphics.TEXT_JUSTIFY_RIGHT);
        dc.drawText(cx + 6, 172, Graphics.FONT_SMALL, fmtTime(info.timerTime != null ? info.timerTime / 1000 : 0), Graphics.TEXT_JUSTIFY_LEFT);

        // Heading from GPS course (compass is unreliable inside a car) | altitude
        var hdg = "--";
        if (drive.hasFix() && drive.gps.heading != null && spd >= drive.stopMps) {
            var deg = (Math.toDegrees(drive.gps.heading).toNumber() + 360) % 360;
            hdg = cardinal(deg) + " " + deg;
        }
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx - 6, 204, Graphics.FONT_TINY, hdg, Graphics.TEXT_JUSTIFY_RIGHT);
        dc.drawText(cx + 6, 204, Graphics.FONT_TINY, fmtAlt(info.altitude), Graphics.TEXT_JUSTIFY_LEFT);
    }
}
