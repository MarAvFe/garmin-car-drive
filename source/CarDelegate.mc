import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

// Input for the three pages: START = start/pause, UP/DOWN = page, hold UP = settings (idle) or map pan/zoom (map page)
class PageDelegate extends WatchUi.BehaviorDelegate {

    var page as Number;

    function initialize(p as Number) {
        BehaviorDelegate.initialize();
        page = p;
    }

    function onSelect() as Boolean {
        var drive = getApp().drive;
        if (drive.isRecording()) {
            drive.pause();
            var menu = new WatchUi.Menu2({:title => "Drive paused"});
            menu.addItem(new WatchUi.MenuItem("Resume", null, :resume, null));
            menu.addItem(new WatchUi.MenuItem("Save", null, :save, null));
            menu.addItem(new WatchUi.MenuItem("Discard", null, :discard, null));
            WatchUi.pushView(menu, new StopMenuDelegate(), WatchUi.SLIDE_UP);
        } else {
            drive.start();
        }
        return true;
    }

    function onNextPage() as Boolean {
        return show(1, WatchUi.SLIDE_UP);
    }

    function onPreviousPage() as Boolean {
        return show(2, WatchUi.SLIDE_DOWN);
    }

    // step 1 = next, 2 = previous (mod 3)
    function show(step as Number, slide as WatchUi.SlideType) as Boolean {
        var p = (page + step) % 3;
        if (p == 1 && !getApp().drive.seenFix) {
            p = (p + step) % 3; // the native map view crashes if it has never had a position
        }
        WatchUi.switchToView(getApp().pages[p], new PageDelegate(p), slide);
        return true;
    }

    function onMenu() as Boolean {
        if (page == 1) {
            var map = getApp().pages[1] as MapPage;
            map.setMapMode(map.getMapMode() == WatchUi.MAP_MODE_BROWSE ? WatchUi.MAP_MODE_PREVIEW : WatchUi.MAP_MODE_BROWSE);
        } else if (getApp().drive.session == null) {
            var menu = new WatchUi.Menu2({:title => "Settings"});
            var d = getApp().drive;
            menu.addItem(new WatchUi.ToggleMenuItem("Navigation", null, "navOn", d.navOn, null));
            menu.addItem(new WatchUi.MenuItem("Stopped below", d.stopKmh + " km/h", "stopKmh", null));
            menu.addItem(new WatchUi.MenuItem("Off-course alert", d.offCourseM + " m", "offCourseM", null));
            WatchUi.pushView(menu, new SettingsDelegate(), WatchUi.SLIDE_UP);
        }
        return true;
    }

    function onBack() as Boolean {
        if (page == 1) {
            var map = getApp().pages[1] as MapPage;
            if (map.getMapMode() == WatchUi.MAP_MODE_BROWSE) {
                map.setMapMode(WatchUi.MAP_MODE_PREVIEW);
                return true;
            }
        }
        // Back must not exit with a drive open; leaving goes through the stop menu
        return getApp().drive.session != null;
    }
}

class StopMenuDelegate extends WatchUi.Menu2InputDelegate {

    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var drive = getApp().drive;
        var id = item.getId();
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        if (id == :resume) {
            drive.start();
        } else if (id == :save) {
            drive.save();
            WatchUi.pushView(new DataPage(drive, :summary), new WatchUi.BehaviorDelegate(), WatchUi.SLIDE_UP);
        } else {
            // No -> stays paused; START resumes
            WatchUi.pushView(new WatchUi.Confirmation("Discard drive?"), new DiscardDelegate(), WatchUi.SLIDE_IMMEDIATE);
        }
    }
}

class DiscardDelegate extends WatchUi.ConfirmationDelegate {

    function initialize() {
        ConfirmationDelegate.initialize();
    }

    function onResponse(response as WatchUi.Confirm) as Boolean {
        if (response == WatchUi.CONFIRM_YES) {
            getApp().drive.discard();
        }
        return true;
    }
}

// On-watch settings: sideloaded apps can't be configured from the Garmin Connect phone app
class SettingsDelegate extends WatchUi.Menu2InputDelegate {

    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var key = item.getId() as String;
        if (item instanceof WatchUi.ToggleMenuItem) {
            Properties.setValue(key, item.isEnabled());
        } else {
            var vals = key.equals("stopKmh") ? [1, 2, 3, 5, 8] : [50, 100, 200, 500];
            var v = vals[(vals.indexOf(Properties.getValue(key)) + 1) % vals.size()];
            Properties.setValue(key, v);
            item.setSubLabel(v + (key.equals("stopKmh") ? " km/h" : " m"));
        }
        getApp().drive.loadSettings();
    }
}
