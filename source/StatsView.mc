import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// Page 3 (live stats) and the post-drive summary (when given a saved snapshot)
class StatsView extends WatchUi.View {

    var drive as Drive;
    var saved as Dictionary?;

    function initialize(d as Drive, s as Dictionary?) {
        View.initialize();
        drive = d;
        saved = s;
    }

    function onUpdate(dc as Dc) as Void {
        var s = saved != null ? saved : drive.stats();
        var cx = dc.getWidth() / 2;
        var moving = s[:moving] as Number;
        var dist = s[:dist] as Float?;

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 14, Graphics.FONT_XTINY, saved != null ? "DRIVE SAVED" : "DRIVE", Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(Graphics.COLOR_ORANGE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 34, Graphics.FONT_MEDIUM, "MAX " + fmtSpeed(s[:max] as Float?) + speedUnit(), Graphics.TEXT_JUSTIFY_CENTER);

        var rows = [
            "Avg moving " + fmtSpeed(dist != null && moving > 0 ? dist / moving : null) + speedUnit(),
            fmtDist(dist) + "   " + fmtTime(s[:elapsed] as Number),
            "Moving " + fmtTime(moving),
            "Stopped " + fmtTime(s[:stopped] as Number) + " (" + s[:stops] + ")",
            "+" + fmtAlt(s[:ascent] as Number?) + "  -" + fmtAlt(s[:descent] as Number?),
            "Alt " + fmtAlt(s[:altMin] as Float?) + " - " + fmtAlt(s[:altMax] as Float?)
        ];
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        for (var i = 0; i < rows.size(); i++) {
            dc.drawText(cx, 76 + i * 25, Graphics.FONT_XTINY, rows[i], Graphics.TEXT_JUSTIFY_CENTER);
        }
    }
}
