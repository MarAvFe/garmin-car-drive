import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Position;
import Toybox.WatchUi;

// Page 2: device map centred on the current position, with the breadcrumb and (nav on) the route
class MapPage extends WatchUi.MapTrackView {

    var drive as Drive;
    var shownVer as Number = -1;

    function initialize(d as Drive) {
        MapTrackView.initialize();
        drive = d;
        setMapMode(WatchUi.MAP_MODE_PREVIEW);
    }

    function onLayout(dc as Dc) as Void {
        setScreenVisibleArea(0, 0, dc.getWidth(), dc.getHeight());
    }

    function onShow() as Void {
        // Initial zoom: ~2 km across. Not in onUpdate: setMapVisibleArea redraws and flickers.
        if (drive.hasFix()) {
            var p = drive.gps.position.toDegrees();
            setMapVisibleArea(
                new Position.Location({:latitude => p[0] + 0.009, :longitude => p[1] - 0.012, :format => :degrees}),
                new Position.Location({:latitude => p[0] - 0.009, :longitude => p[1] + 0.012, :format => :degrees}));
        }
    }

    function onUpdate(dc as Dc) as Void {
        if (shownVer != drive.mapVer) {
            clear();
            // unverified: in the simulator only one line showed; route goes last so it wins when nav is on
            if (drive.trail != null && drive.trailN >= 2) {
                setPolyline(drive.trail);
            }
            if (drive.navOn && drive.routeLine != null) {
                setPolyline(drive.routeLine);
            }
            shownVer = drive.mapVer;
        }
        if (!drive.hasFix()) {
            // don't render a position-tracking map with no position
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE);
            dc.clear();
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
            dc.drawText(dc.getWidth() / 2, dc.getHeight() / 2, Graphics.FONT_SMALL, "Map: waiting for GPS", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            return;
        }
        MapView.onUpdate(dc);

        if (!drive.navOn || drive.offM == null) {
            return; // FR-M6: nav off shows only the past track
        }
        var off = drive.isOffCourse();
        dc.setColor(off ? Graphics.COLOR_WHITE : Graphics.COLOR_BLACK, off ? Graphics.COLOR_RED : Graphics.COLOR_WHITE);
        dc.drawText(dc.getWidth() / 2, dc.getHeight() - 50, Graphics.FONT_XTINY,
            off ? " OFF " + fmtAlt(drive.offM) + "  " + drive.offS / 60 + ":" + (drive.offS % 60).format("%02d") + " " : " " + fmtDist(drive.leftM) + " left ",
            Graphics.TEXT_JUSTIFY_CENTER);
    }
}
