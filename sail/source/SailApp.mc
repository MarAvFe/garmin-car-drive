import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class SailApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() as [Views] or [Views, InputDelegates] {
        return [new SailField()];
    }
}
