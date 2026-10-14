import Toybox.Application;
import Toybox.Lang;
import Toybox.Position;
import Toybox.Timer;
import Toybox.WatchUi;

class CarApp extends Application.AppBase {

    var drive as Drive?;
    var pages as Array<WatchUi.View> = [];
    var timer as Timer.Timer?;

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Dictionary?) as Void {
        drive = new Drive();
        var opts = {:acquisitionType => Position.LOCATION_CONTINUOUS};
        // GPS-only is the lowest-power config; a car track doesn't need multi-band
        if (Position has :hasConfigurationSupport && Position.hasConfigurationSupport(Position.CONFIGURATION_GPS)) {
            opts[:configuration] = Position.CONFIGURATION_GPS;
        }
        Position.enableLocationEvents(opts, method(:onPosition));
        timer = new Timer.Timer();
        timer.start(method(:tick), 1000, true);
    }

    function onStop(state as Dictionary?) as Void {
        // NFR-3: an open drive is saved, never lost, if the app is closed underneath us
        drive.save();
        Position.enableLocationEvents(Position.LOCATION_DISABLE, null);
    }

    function onPosition(info as Position.Info) as Void {
        drive.gps = info;
    }

    function tick() as Void {
        drive.tick();
        WatchUi.requestUpdate();
    }

    function onSettingsChanged() as Void {
        drive.loadSettings();
        WatchUi.requestUpdate();
    }

    function getInitialView() as [Views] or [Views, InputDelegates] {
        pages = [new CarView(drive), new MapPage(drive), new StatsView(drive, null)];
        return [pages[0], new PageDelegate(0)];
    }
}

function getApp() as CarApp {
    return Application.getApp() as CarApp;
}
